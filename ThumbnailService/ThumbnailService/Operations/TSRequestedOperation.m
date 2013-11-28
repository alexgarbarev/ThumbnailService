//
//  TSOperation+Requests.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 18.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequestedOperation.h"
#import "TSOperation+Private.h"

@interface TSRequestedOperation ()

@property (nonatomic, strong) NSMutableSet *requests;

@end

@implementation TSRequestedOperation

- (id)init
{
    self = [super init];
    if (self) {
        self.requests = [NSMutableSet new];
    }
    return self;
}

#pragma mark - Managing requests

- (void) addRequest:(TSRequest *)request andWait:(BOOL)wait
{
    dispatch_block_t work = ^{
        [self.requests addObject:request];
        [self _updatePriority];
    };
    
    if (wait) {
        dispatch_sync(self.operationQueue, work);
    } else {
        dispatch_async(self.operationQueue, work);
    }
}

- (void) removeRequest:(TSRequest *)request andWait:(BOOL)wait
{
    dispatch_block_t work = ^{
        [self.requests removeObject:request];
        
        if ([self.requests count] > 0) {
            [self _updatePriority];
        } else {
            [self cancel];
        }
    };
    
    if (wait) {
        dispatch_sync(self.operationQueue, work);
    } else {
        dispatch_async(self.operationQueue, work);
    }
}


- (void) enumerationRequests:(void(^)(TSRequest *anRequest))enumerationBlock onQueue:(dispatch_queue_t)queue
{
    if (!enumerationBlock) {
        return;
    }
    
    NSParameterAssert(queue);
    
    dispatch_sync(self.operationQueue, ^{
        dispatch_sync(queue, ^{
            for (TSRequest *request in self.requests) {
                enumerationBlock(request);
            };
        });
    });
}

- (BOOL) shouldCacheOnDisk
{
    __block BOOL shouldCache = NO;
    dispatch_sync(self.operationQueue, ^{
        for (TSRequest *requst in self.requests) {
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
    dispatch_sync(self.operationQueue, ^{
        for (TSRequest *requst in self.requests) {
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
    dispatch_sync(self.operationQueue, ^{
        [self _updatePriority];
    });
}

- (void) _updatePriority
{
    TSRequestThreadPriority tPriority = TSRequestThreadPriorityBackground;
    TSRequestQueuePriority priority = TSRequestQueuePriorityVeryLow;
    
    for (TSRequest *request in self.requests) {
        if (request.queuePriority > priority) {
            priority = request.queuePriority;
        }
        if (request.threadPriority > tPriority) {
            tPriority = request.threadPriority;
        }
    }
    
    self.queuePriority = priority;
    
    if (![self isExecuting]) {
        self.dispatchQueuePriority = OperationDispatchQueuePriorityFromRequestThreadPriority(tPriority);
    }
}

TSOperationDispatchQueuePriority OperationDispatchQueuePriorityFromRequestThreadPriority(TSRequestThreadPriority requestPriority)
{
    return (TSOperationDispatchQueuePriority)requestPriority;
}

@end
