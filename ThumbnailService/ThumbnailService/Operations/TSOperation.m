//
//  TSOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperation.h"
#import <pthread.h>

@implementation TSOperation {
    NSMutableSet *requests;
    
    NSMutableSet *completionBlocks;
    NSMutableSet *cancelBlocks;
    
    dispatch_queue_t synchronizationQueue;
}

- (id) init
{
    self = [super init];
    if (self) {
        requests = [NSMutableSet new];
        completionBlocks = [NSMutableSet new];
        cancelBlocks = [NSMutableSet new];
       
        synchronizationQueue = dispatch_queue_create("synchronizationQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(synchronizationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        
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
        [completionBlocks addObject:completionBlock];
    });
}

- (void) addCancelBlock:(TSOperationCompletion)cancelBlock
{
    dispatch_sync(synchronizationQueue, ^{
        [cancelBlocks addObject:cancelBlock];
    });
}

- (void) callCancelBlocks
{
    dispatch_sync(synchronizationQueue, ^{
        for (TSOperationCompletion cancel in cancelBlocks) {
            cancel(self);
        }
    });
}

- (void) callCompleteBlocks
{
    dispatch_sync(synchronizationQueue, ^{
        for (TSOperationCompletion complete in completionBlocks) {
            complete(self);
        }
    });
}

@end
