//
//  TSOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperation.h"
#import "TSOperation+Private.h"

@interface TSOperation ()

@property (nonatomic, strong) NSMutableSet *completionBlocks;
@property (nonatomic, strong) NSMutableSet *cancelBlocks;

@property (nonatomic, getter = isFinished)  BOOL finished;
@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isStarted)   BOOL started;

@end

@implementation TSOperation {
    TSOperationDispatchQueuePriority dispatchQueuePriority;
}

@synthesize completionBlocks = _completionBlocks;
@synthesize cancelBlocks = _cancelBlocks;

- (id) init
{
    self = [super init];
    if (self) {
        self.completionBlocks = [NSMutableSet new];
        self.cancelBlocks = [NSMutableSet new];
               
        self.callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        __weak typeof (self) weakSelf = self;
        [super setCompletionBlock:^{
            [weakSelf onComplete];
        }];
    }
    return self;
}

- (void) dealloc
{

}

- (void) synchronize:(dispatch_block_t)block
{
    @synchronized(self){
        block();
    }
}

#pragma mark - NSOperation cuncurrent support

- (void) start
{
    self.started = YES;
    if (![self isCancelled]) {
        self.executing = YES;
        dispatch_async(dispatch_get_global_queue(GlobalQueuePriorityFromDispatchQueuePriority(self.dispatchQueuePriority), 0), ^{
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

- (BOOL) isCancelled
{
    return [super isCancelled];
}

- (void) cancel
{
    if (self.started && !self.finished) {
        self.finished = YES;
    }

    [self onCancel];
    [super cancel];
}

#pragma mark - Thread priority

- (void) setDispatchQueuePriority:(TSOperationDispatchQueuePriority)priority
{
    dispatchQueuePriority = priority;
}

- (TSOperationDispatchQueuePriority) dispatchQueuePriority
{
    return dispatchQueuePriority;
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

- (void) setExecuting:(BOOL)isExecuting
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void) setFinished:(BOOL)isFinished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - Callbacks

- (void) addCompleteBlock:(TSOperationCompletion)completionBlock
{
    [self synchronize:^{
        [_completionBlocks addObject:completionBlock];
    }];
}

- (void) addCancelBlock:(TSOperationCompletion)cancelBlock
{
    [self synchronize:^{
        [_cancelBlocks addObject:cancelBlock];
    }];
}

- (NSMutableSet *) completionBlocks
{
    __block NSMutableSet *set;
    [self synchronize:^{
        set = _completionBlocks;
    }];
    return set;
}

- (NSMutableSet *) cancelBlocks
{
    __block NSMutableSet *set;
    [self synchronize:^{
        set = _cancelBlocks;
    }];
    return set;
}

- (void) callCancelBlocks
{
    dispatch_async(self.callbackQueue, ^{
        for (TSOperationCompletion cancel in self.cancelBlocks) {
            cancel(self);
        }
    });
}

- (void) callCompleteBlocks
{
    dispatch_async(self.callbackQueue, ^{
        for (TSOperationCompletion complete in self.completionBlocks) {
            complete(self);
        }
    });
}

dispatch_queue_priority_t GlobalQueuePriorityFromDispatchQueuePriority(TSOperationDispatchQueuePriority priority)
{
    switch (priority) {
        case TSOperationDispatchQueuePriorityBackground:
            return DISPATCH_QUEUE_PRIORITY_BACKGROUND;
        default:
        case TSOperationDispatchQueuePriorityLow:
            return DISPATCH_QUEUE_PRIORITY_LOW;
        case TSOperationDispatchQueuePriorityNormal:
            return DISPATCH_QUEUE_PRIORITY_DEFAULT;
        case TSOperationDispatchQueuePriorityHight:
            return DISPATCH_QUEUE_PRIORITY_HIGH;
    }
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@ %p. Cancelled=%d, Finished=%d, Started=%d, Executing=%d>",[self class], self,[self isCancelled], [self isFinished], [self isStarted], [self isExecuting]];
}

@end
