//
//  TSOperationQueue.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 11.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperationQueue.h"

@implementation TSOperationQueue {
    NSMutableDictionary *dictionary;
    
    NSMutableSet *cancelBlocks;
    NSMutableSet *completeBlock;
    
    dispatch_queue_t syncQueue;
}

- (id)init
{
    self = [super init];
    if (self) {
        syncQueue = dispatch_queue_create("TSOperationQueueSyncQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(syncQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        
        dictionary = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    dispatch_release(syncQueue);
}

- (void) addOperation:(TSOperation *)operation forIdentifider:(NSString *)identifier
{
    [super addOperation:operation];
    
    dispatch_async(syncQueue, ^{
        dictionary[identifier] = operation;
    });

    __weak typeof (self) weakSelf = self;
    [operation addCancelBlock:^(TSOperation *operation) {
        [weakSelf operationDidFinishForIdentifier:identifier];
    }];
    [operation addCompleteBlock:^(TSOperation *operation) {
        [weakSelf operationDidFinishForIdentifier:identifier];
    }];
}

- (TSOperation *) operationWithIdentifier:(NSString *)identifier
{
    __block TSOperation *operation = nil;
    dispatch_sync(syncQueue, ^{
        operation = dictionary[identifier];
    });
    return operation;
}

- (void) operationDidFinishForIdentifier:(NSString *)identifier
{
    dispatch_async(syncQueue, ^{
        [dictionary removeObjectForKey:identifier];
    });
}

@end
