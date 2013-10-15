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

@end

@implementation TSOperation {
    NSMutableSet *requests;
    
    dispatch_queue_t operationQueue;
    dispatch_queue_t callbackQueue;
    
    int completionCalled;
    int calledFromBlock;
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

- (void)dealloc
{
    dispatch_release(operationQueue);
    dispatch_release(callbackQueue);
}

- (void) cancel
{
    [self onCancel];
    [super cancel];
}

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

- (NSSet *) requests
{
    __block NSSet *result;
    dispatch_sync(operationQueue, ^{
        result = requests;
    });
    return result;
}

- (void) enumerationRequests:(void(^)(TSRequest *anRequest))enumerationBlock onQueue:(dispatch_queue_t)queue
{
    if (!enumerationBlock) {
        return;
    }
    
    dispatch_sync(operationQueue, ^{
        dispatch_sync(queue, ^{
            for (TSRequest *request in requests) {
                enumerationBlock(request);
            };
        });
    });
}

- (void) updatePriority
{
    dispatch_sync(operationQueue, ^{
        [self _updatePriority];
    });
}

- (void) _updatePriority
{
    NSOperationQueuePriority priority = NSOperationQueuePriorityVeryLow;
    
    for (TSRequest *request in requests) {
        if (request.priority > priority) {
            priority = request.priority;
        }
    }
    
    self.queuePriority = priority;
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

- (NSMutableSet *)completionBlocks
{
    __block NSMutableSet *set;
    dispatch_sync(operationQueue, ^{
        set = _completionBlocks;
    });
    return set;
}

- (NSMutableSet *)cancelBlocks
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
