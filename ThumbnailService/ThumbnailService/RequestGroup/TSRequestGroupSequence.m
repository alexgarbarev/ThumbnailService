//
//  TSRequestGroupSequence.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 13.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequestGroupSequence.h"
#import "TSRequest+Private.h"
#import "DispatchReleaseMacro.h"

typedef NS_ENUM(NSInteger, TSRequestGroupSequenceState) {
    TSRequestGroupSequenceNotStarted,
    TSRequestGroupSequenceStarted,
    TSRequestGroupSequenceCanceled,
    TSRequestGroupSequenceFinished
};

@interface TSRequestGroupSequence ()

@property (nonatomic) TSRequestGroupSequenceState state;

@end

@implementation TSRequestGroupSequence {
    NSMutableArray *sequence;
    
    dispatch_queue_t groupSyncQueue;
    dispatch_semaphore_t semaphore;
    
    NSInteger stepNumber;
}

- (id)init
{
    self = [super init];
    if (self) {
        sequence = [NSMutableArray new];
        semaphore = dispatch_semaphore_create(0);

        groupSyncQueue = dispatch_queue_create("TSRequestGroupSequenceQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(groupSyncQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

        self.state = TSRequestGroupSequenceNotStarted;
    }
    return self;
}

- (void)dealloc
{
    TSDispatchRelease(groupSyncQueue);
    TSDispatchRelease(semaphore);
}

- (void)addRequest:(TSRequest *)request
{
    dispatch_async(groupSyncQueue, ^{
        [sequence addObject:request];
        request.group = self;
    });
}

- (NSArray *)pullPendingRequests
{
    __block NSArray *requests = nil;

    dispatch_sync(groupSyncQueue, ^{

        if (stepNumber == 0) {
            self.state = TSRequestGroupSequenceStarted;
        }
        stepNumber++;

        if ([sequence count] > 0) {
            TSRequest *request = [sequence firstObject];
            requests = @[request];
        }
    });

    return requests;
}

- (void)didFinishRequest:(TSRequest *)request
{
    dispatch_async(groupSyncQueue, ^{
        [sequence removeObject:request];
        if (sequence.count == 0) {
            self.state = TSRequestGroupSequenceFinished;
            request.group = nil;
        }
    });
}

- (void)didCancelRequest:(TSRequest *)__unused request
{

}

- (void)cancel
{
    dispatch_sync(groupSyncQueue, ^{
        self.state = TSRequestGroupSequenceCanceled;
        for (TSRequest *request in sequence) {
            [request cancel];
        }
        sequence = nil;
    });
}

- (BOOL)isFinished
{
    return _state == TSRequestGroupSequenceCanceled || _state == TSRequestGroupSequenceFinished;
}

- (void)setState:(TSRequestGroupSequenceState)state
{
    _state = state;

    if ([self isFinished]) {
        dispatch_semaphore_signal(semaphore);
    }
}

- (void)waitUntilFinished
{
    if (![self isFinished]) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}

@end
