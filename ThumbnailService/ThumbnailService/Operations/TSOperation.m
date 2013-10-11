//
//  TSOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperation.h"

@implementation TSOperation {
    NSMutableSet *requests;
    
    NSMutableSet *completionBlocks;
    NSMutableSet *cancelBlocks;
}

- (id) init
{
    self = [super init];
    if (self) {
        requests = [NSMutableSet new];
        completionBlocks = [NSMutableSet new];
        cancelBlocks = [NSMutableSet new];
        
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
    [requests addObject:request];
    [self updatePriority];
}

- (void) removeRequest:(TSRequest *)request
{
    [requests removeObject:request];

    if ([requests count] > 0) {
        [self updatePriority];
    } else {
        [self cancel];
    }
}

- (NSSet *) requests
{
    return requests;
}

- (void) updatePriority
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
    [completionBlocks addObject:completionBlock];
}

- (void) addCancelBlock:(TSOperationCompletion)cancelBlock
{
    [cancelBlocks addObject:cancelBlock];
}

- (void) callCancelBlocks
{
    for (TSOperationCompletion cancel in cancelBlocks) {
        cancel(self);
    }
}

- (void) callCompleteBlocks
{
    for (TSOperationCompletion complete in completionBlocks) {
        complete(self);
    }
}

@end
