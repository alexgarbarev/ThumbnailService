//
//  TSOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperation.h"

@interface TSOperation ()

@property (nonatomic, strong) NSMutableSet *completionBlocks;
@property (nonatomic, strong) NSMutableSet *cancelBlocks;

@property (nonatomic, getter = isFinished)  BOOL finished;
@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isStarted)   BOOL started;

@end

@implementation TSOperation {
    NSMutableSet *requests;
    
    dispatch_queue_t operationQueue;
    dispatch_queue_t callbackQueue;
    
    int completionCalled;
    int calledFromBlock;
    
    TSOperationThreadPriority threadPriority;
}

@synthesize completionBlocks = _completionBlocks;
@synthesize cancelBlocks = _cancelBlocks;

- (id) init
{
    self = [super init];
    if (self) {
        completionCalled = 0;
        calledFromBlock = 0;
        
        requests = [NSMutableSet new];
        self.completionBlocks = [NSMutableSet new];
        self.cancelBlocks = [NSMutableSet new];
       
        operationQueue = dispatch_queue_create("TSOperationQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(operationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        
        callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        __weak typeof (self) weakSelf = self;
        [super setCompletionBlock:^{
            [weakSelf onComplete];
        }];
    }
    return self;
}

- (void) dealloc
{
    dispatch_release(operationQueue);
    dispatch_release(callbackQueue);
}

#pragma mark - NSOperation cuncurrent support

- (void) start
{
    self.started = YES;
    if (![self isCancelled]) {
        self.executing = YES;
        dispatch_async(dispatch_get_global_queue([self queuePriorityFromThreadPriority:self.threadPriority], 0), ^{
            [self main];
            self.executing = NO;
            self.finished = YES;
        });
    } else {
        self.finished = YES;
    }
}

- (BOOL) isConcurrent
{
    return YES;
}

- (void) cancel
{
    if (self.started && !self.finished) {
        self.finished = YES;
    }

    [self onCancel];
    [super cancel];
}

- (dispatch_queue_priority_t)queuePriorityFromThreadPriority:(TSOperationThreadPriority)priority
{
    switch (priority) {
        case TSOperationThreadPriorityBackground:
            return DISPATCH_QUEUE_PRIORITY_BACKGROUND;
        default:
        case TSOperationThreadPriorityLow:
            return DISPATCH_QUEUE_PRIORITY_LOW;
        case TSOperationThreadPriorityNormal:
            return DISPATCH_QUEUE_PRIORITY_DEFAULT;
        case TSOperationThreadPriorityHight:
            return DISPATCH_QUEUE_PRIORITY_HIGH;
    }
}

#pragma mark - Managing requests

- (void) addRequest:(TSRequest *)request andWait:(BOOL)wait
{
    dispatch_block_t work = ^{
        [requests addObject:request];
        [self _updatePriority];
    };
    
    if (wait) {
        dispatch_sync(operationQueue, work);
    } else {
        dispatch_async(operationQueue, work);
    }
}

- (void) removeRequest:(TSRequest *)request andWait:(BOOL)wait
{
    dispatch_block_t work = ^{
        [requests removeObject:request];
        
        if ([requests count] > 0) {
            [self _updatePriority];
        } else {
            [self cancel];
        }
    };
    
    if (wait) {
        dispatch_sync(operationQueue, work);
    } else {
        dispatch_async(operationQueue, work);
    }
}


- (void) enumerationRequests:(void(^)(TSRequest *anRequest))enumerationBlock onQueue:(dispatch_queue_t)queue
{
    if (!enumerationBlock) {
        return;
    }
    
    NSParameterAssert(queue);
    
    dispatch_sync(operationQueue, ^{
        dispatch_sync(queue, ^{
            for (TSRequest *request in requests) {
                enumerationBlock(request);
            };
        });
    });
}

- (BOOL) shouldCacheOnDisk
{
    __block BOOL shouldCache = NO;
    dispatch_sync(operationQueue, ^{
        for (TSRequest *requst in requests) {
            if (requst.shouldCacheOnDisk) {
                shouldCache = YES;
                break;
            }
        }
    });
    return shouldCache;
}

- (BOOL) shouldCacheInMemory
{
    __block BOOL shouldCache = NO;
    dispatch_sync(operationQueue, ^{
        for (TSRequest *requst in requests) {
            if (requst.shouldCacheInMemory) {
                shouldCache = YES;
                break;
            }
        }
    });
    return shouldCache;
}


- (void) updatePriority
{
    dispatch_sync(operationQueue, ^{
        [self _updatePriority];
    });
}

- (void) _updatePriority
{
    TSOperationThreadPriority tPriority = TSOperationThreadPriorityBackground;
    TSRequestQueuePriority priority = TSRequestQueuePriorityVeryLow;
    
    for (TSRequest *request in requests) {
        if (request.queuePriority > priority) {
            priority = request.queuePriority;
        }
        if ((TSOperationThreadPriority)request.threadPriority > tPriority) {
            tPriority = (TSOperationThreadPriority)request.threadPriority;
        }
    }
    
    self.queuePriority = priority;
    
    if (!self.executing) {
        self.threadPriority = tPriority;
    }
}

#pragma mark - Thread priority

- (void) setThreadPriority:(TSOperationThreadPriority)priority
{
    threadPriority = priority;
}

- (TSOperationThreadPriority) threadPriority
{
    return threadPriority;
}

#pragma mark - Operation termination

- (void) onComplete
{
    if (![self isCancelled]) {
        [self callCompleteBlocks];
    }
}

- (void) onCancel
{
    [self callCancelBlocks];
}

#pragma mark - KVO notifications

- (void)setExecuting:(BOOL)isExecuting
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)isFinished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - Callbacks

- (void) addCompleteBlock:(TSOperationCompletion)completionBlock
{
    dispatch_sync(operationQueue, ^{
        [_completionBlocks addObject:completionBlock];
    });
}

- (void) addCancelBlock:(TSOperationCompletion)cancelBlock
{
    dispatch_sync(operationQueue, ^{
        [_cancelBlocks addObject:cancelBlock];
    });
}

- (NSMutableSet *) completionBlocks
{
    __block NSMutableSet *set;
    dispatch_sync(operationQueue, ^{
        set = _completionBlocks;
    });
    return set;
}

- (NSMutableSet *) cancelBlocks
{
    __block NSMutableSet *set;
    dispatch_sync(operationQueue, ^{
        set = _cancelBlocks;
    });
    return set;
}

- (void) callCancelBlocks
{
    dispatch_async(callbackQueue, ^{
        for (TSOperationCompletion cancel in self.cancelBlocks) {
            cancel(self);
        }
    });
}

- (void) callCompleteBlocks
{
    dispatch_async(callbackQueue, ^{
        for (TSOperationCompletion complete in self.completionBlocks) {
            complete(self);
        }
    });
}

@end
