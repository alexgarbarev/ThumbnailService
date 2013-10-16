//
//  TSRequestGroupSequence.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 13.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequestGroupSequence.h"
#import "TSRequest+Private.h"

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
    
    dispatch_queue_t queue;
    dispatch_semaphore_t semaphore;
    
    NSInteger stepNumber;
}

- (id)init
{
    self = [super init];
    if (self) {
        sequence = [NSMutableArray new];
        semaphore = dispatch_semaphore_create(0);
        
        queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        
        self.state = TSRequestGroupSequenceNotStarted;
    }
    return self;
}

- (void)dealloc
{
    dispatch_release(queue);
    dispatch_release(semaphore);
}

- (void) addRequest:(TSRequest *)request runOnMainThread:(BOOL)onMainThread;
{
    dispatch_async(queue, ^{
        [sequence addObject:request];
        request.group = self;
    });
}

- (NSArray *) pullPendingRequests
{
    __block NSArray *requests = nil;

    dispatch_sync(queue, ^{
        
        if (stepNumber == 0) {
            self.state = TSRequestGroupSequenceStarted;
        }
        stepNumber++;
        
        if ([sequence count] > 0) {
            TSRequest *request = [sequence objectAtIndex:0];
            requests = @[request];
        }
    });
    
    return requests;
}

- (void) didFinishRequest:(TSRequest *)request
{
    dispatch_async(queue, ^{
        [sequence removeObject:request];
        if (sequence.count == 0) {
            self.state = TSRequestGroupSequenceFinished;
        }
    });
}

- (void) didCancelRequest:(TSRequest *)request
{

}

- (void) cancelAndWait:(BOOL)wait
{
    dispatch_block_t work = ^{
        self.state = TSRequestGroupSequenceCanceled;
        for (TSRequest *request in sequence) {
            [request cancel];
        }
        sequence = nil;
    };
    
    if (wait) {
        dispatch_sync(queue, work);
    } else {
        dispatch_async(queue, work);
    }
}

- (void) cancel
{
    [self cancelAndWait:YES];
}

- (BOOL) isGroupFinished
{
    return _state == TSRequestGroupSequenceCanceled || _state == TSRequestGroupSequenceFinished;
}

- (void)setState:(TSRequestGroupSequenceState)state
{
    _state = state;
    
    if ([self isGroupFinished]) {
        dispatch_semaphore_signal(semaphore);
    }
}

- (void) waitUntilFinished
{
    if (![self isGroupFinished]) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}


@end
