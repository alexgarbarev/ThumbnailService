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
    
    dispatch_queue_t synchronizationQueue;
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
       
        synchronizationQueue = dispatch_queue_create("synchronizationQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(synchronizationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        
        callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        __weak typeof (self) weakSelf = self;
        [super setCompletionBlock:^{
            [weakSelf onComplete];
        }];
    }
    return self;
}

- (void) cancel
{
    [self onCancel];
    [super cancel];
}

- (void) addRequest:(TSRequest *)request
{
    dispatch_sync(synchronizationQueue, ^{
        [requests addObject:request];
        [self _updatePriority];
    });
}

- (void) removeRequest:(TSRequest *)request
{
    dispatch_sync(synchronizationQueue, ^{
        [requests removeObject:request];
        
        if ([requests count] > 0) {
            [self _updatePriority];
        } else {
            [self cancel];
        }
    });
}

- (NSSet *) requests
{
    __block NSSet *result;
    dispatch_sync(synchronizationQueue, ^{
        result = requests;
    });
    return result;
}

- (void) updatePriority
{
    dispatch_sync(synchronizationQueue, ^{
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
    [self callCompleteBlocks];
}

- (void) onCancel
{
    [self callCancelBlocks];
}

#pragma mark - Callbacks

- (void) addCompleteBlock:(TSOperationCompletion)completionBlock
{
    dispatch_sync(synchronizationQueue, ^{
        [_completionBlocks addObject:completionBlock];
    });
}

- (void) addCancelBlock:(TSOperationCompletion)cancelBlock
{
    dispatch_sync(synchronizationQueue, ^{
        [_cancelBlocks addObject:cancelBlock];
    });
}

- (NSMutableSet *)completionBlocks
{
    __block NSMutableSet *set;
    dispatch_sync(synchronizationQueue, ^{
        set = _completionBlocks;
    });
    return set;
}

- (NSMutableSet *)cancelBlocks
{
    __block NSMutableSet *set;
    dispatch_sync(synchronizationQueue, ^{
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

- (void) callCompleteBlocksOnMainThread
{
    dispatch_block_t completion = ^{
        for (TSOperationCompletion complete in self.completionBlocks) {
            complete(self);
        }
    };

    if ([NSThread isMainThread]) {
        completion();
    } else {
        dispatch_async(dispatch_get_main_queue(), completion);
    }
}

#pragma mark - Manual running

- (void) runOnMainThread
{
    [super setCompletionBlock:nil];
    [self start];
    [self callCompleteBlocksOnMainThread];
}


@end
