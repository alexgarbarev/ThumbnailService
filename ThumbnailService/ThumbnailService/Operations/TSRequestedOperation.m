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

- (void) addRequest:(TSRequest *)request
{
    [self synchronize:^{
        [self.requests addObject:request];
        [self _updatePriority];
    }];
}

- (void) removeRequest:(TSRequest *)request
{
    [self synchronize:^{
        [self.requests removeObject:request];
        
        if ([self.requests count] > 0) {
            [self _updatePriority];
        } else if (![self isCancelled]){
            [self cancel];
        }
    }];
}


- (void) enumerateRequests:(void(^)(TSRequest *anRequest))enumerationBlock
{
    if (!enumerationBlock) {
        return;
    }
    
    [self synchronize:^{
        for (TSRequest *request in self.requests) {
            enumerationBlock(request);
        };
    }];
}

- (BOOL) shouldCacheOnDisk
{
    __block BOOL shouldCache = NO;
    [self synchronize:^{
        for (TSRequest *requst in self.requests) {
            if (requst.shouldCacheOnDisk) {
                shouldCache = YES;
                break;
            }
        }
    }];
    return shouldCache;
}

- (BOOL) shouldCacheInMemory
{
    __block BOOL shouldCache = NO;
    [self synchronize:^{
        for (TSRequest *requst in self.requests) {
            if (requst.shouldCacheInMemory) {
                shouldCache = YES;
                break;
            }
        }
    }];
    return shouldCache;
}


- (void) updatePriority
{
    [self synchronize:^{
        [self _updatePriority];
    }];
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
    
    self.queuePriority = (NSOperationQueuePriority)priority;
    
    if (![self isExecuting]) {
        self.dispatchQueuePriority = OperationDispatchQueuePriorityFromRequestThreadPriority(tPriority);
    }
}

TSOperationDispatchQueuePriority OperationDispatchQueuePriorityFromRequestThreadPriority(TSRequestThreadPriority requestPriority)
{
    return (TSOperationDispatchQueuePriority)requestPriority;
}

@end
