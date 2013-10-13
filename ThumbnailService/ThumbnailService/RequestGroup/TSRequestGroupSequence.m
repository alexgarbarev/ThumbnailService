//
//  TSRequestGroupSequence.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 13.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequestGroupSequence.h"
#import "TSRequest+Private.h"

@implementation TSRequestGroupSequence {
    NSMutableArray *sequence;
    NSMutableDictionary *requestOnMainThread;
    
    dispatch_queue_t queue;
    dispatch_semaphore_t semaphore;
}

- (id)init
{
    self = [super init];
    if (self) {
        sequence = [NSMutableArray new];
        requestOnMainThread = [NSMutableDictionary new];
        semaphore = dispatch_semaphore_create(0);
        
        queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    }
    return self;
}

- (void) addRequest:(TSRequest *)request runOnMainThread:(BOOL)onMainThread;
{
    dispatch_sync(queue, ^{
        [sequence addObject:request];
        requestOnMainThread[request.identifier] = @(onMainThread);
        request.group = self;
    });
}

- (NSArray *) pullPendingRequests
{
    __block NSArray *requests = nil;

    dispatch_sync(queue, ^{
        if ([sequence count] > 0) {
            TSRequest *request = [sequence objectAtIndex:0];
            requests = @[request];
        }
    });
    
    return requests;
}

- (void) didFinishRequest:(TSRequest *)request
{
    dispatch_sync(queue, ^{
        [sequence removeObject:request];
        if (sequence.count == 0) {
            [self finishGroup];
        }
    });
}

- (void) didCancelRequest:(TSRequest *)request
{

}

- (BOOL)shouldPerformOnMainQueueRequest:(TSRequest *)request
{
    return [requestOnMainThread[request.identifier] boolValue];
}

- (void) cancel
{
    dispatch_sync(queue, ^{
        requestOnMainThread = nil;
        [self finishGroup];
        for (TSRequest *request in sequence) {
            [request cancel];
        }
        sequence = nil;
    });
}

- (BOOL) isGroupFinished
{
    return semaphore == NULL;
}

- (void) finishGroup
{
    if (semaphore) {
        dispatch_semaphore_signal(semaphore);
        semaphore = NULL;
    }
}

- (void)waitUntilFinished
{
    if (semaphore != NULL) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}


@end
