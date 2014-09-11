//
//  TSOperationQueue.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 11.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperationQueue.h"
#import "DispatchReleaseMacro.h"

@implementation TSOperationQueue {
    NSMutableDictionary *dictionary;
    dispatch_queue_t syncQueue;
}

- (id)init
{
    self = [super init];
    if (self) {
        syncQueue = dispatch_queue_create("TSOperationQueueSyncQueue", DISPATCH_QUEUE_SERIAL);
        dictionary = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    TSDispatchRelease(syncQueue);
}

- (void)addOperation:(TSOperation *)operation forIdentifider:(NSString *)identifier
{
    [super addOperation:operation];

    dispatch_async(syncQueue, ^{
        dictionary[identifier] = operation;
    });

    __weak __typeof(self) weakSelf = self;
    [operation addCancelBlock:^(__unused TSOperation *operation) {
        [weakSelf operationDidFinishForIdentifier:identifier];
    }];
    [operation addCompleteBlock:^(__unused TSOperation *operation) {
        [weakSelf operationDidFinishForIdentifier:identifier];
    }];
}

- (TSOperation *)operationWithIdentifier:(NSString *)identifier
{
    __block TSOperation *operation = nil;
    dispatch_sync(syncQueue, ^{
        operation = dictionary[identifier];
    });
    return operation;
}

- (void)operationDidFinishForIdentifier:(NSString *)identifier
{
    dispatch_async(syncQueue, ^{
        [dictionary removeObjectForKey:identifier];
    });
}

@end
