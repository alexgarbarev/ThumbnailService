//
//  TSRequestGroupSequence.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 13.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequestGroupSequence.h"

@implementation TSRequestGroupSequence {
    NSMutableArray *sequence;
    
    dispatch_queue_t queue;
}

- (id)init
{
    self = [super init];
    if (self) {
        sequence = [NSMutableArray new];
        
        queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    }
    return self;
}

- (void) addRequestSequence:(NSArray *)requests
{
    dispatch_sync(queue, ^{
        [sequence addObjectsFromArray:requests];
    });
}

- (NSArray *) pullPendingRequests
{
    __block NSArray *requests = nil;

    dispatch_sync(queue, ^{
        if ([sequence count] > 0) {
            TSRequest *request = [sequence objectAtIndex:0];
            [sequence removeObjectAtIndex:0];
            requests = @[request];
        }
    });
    
    return requests;
}

- (void) didFinishRequest:(TSRequest *)request
{
    dispatch_sync(queue, ^{
        [sequence removeObject:request];
    });
}

- (void) didCancelRequest:(TSRequest *)request
{
    dispatch_sync(queue, ^{
        [sequence removeAllObjects];
    });
}


@end
