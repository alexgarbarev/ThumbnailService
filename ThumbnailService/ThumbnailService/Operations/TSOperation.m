//
//  TSOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperation.h"

@implementation TSOperation {
    NSMutableArray *expectators;
    
    BOOL isInternalChangingPriority;
    NSOperationQueuePriority originalPriority;
}

- (id) init
{
    self = [super init];
    if (self) {
        expectators = [NSMutableArray new];
    }
    return self;
}

- (void) cancel
{
    if (self.cancellationBlock) {
        self.cancellationBlock();
    }
    [super cancel];
}

- (void) addExpectantRequest:(TSRequest *)request
{
    [expectators addObject:request];
    [self updatePriority];
}

- (void) removeExpectantRequest:(TSRequest *)request
{
    [expectators removeObject:request];
    [self updatePriority];
}

- (NSArray *) expectantRequests
{
    return expectators;
}

- (void) updatePriority
{
    NSOperationQueuePriority priorityToSet = originalPriority;
    
    for (TSRequest *request in expectators) {
        if (request.priority > priorityToSet) {
            priorityToSet = request.priority;
        }
    }
    
    [self internalChangePriorityInBlock:^{
        self.queuePriority = priorityToSet;
    }];
}

- (void) setQueuePriority:(NSOperationQueuePriority)p
{
    [super setQueuePriority:p];
    
    if (!isInternalChangingPriority) {
        originalPriority = p;
        [self updatePriority];
    }
}

#pragma mark - Utils

- (void) internalChangePriorityInBlock:(dispatch_block_t)block
{
    isInternalChangingPriority = YES;
    block();
    isInternalChangingPriority = NO;
}

@end
