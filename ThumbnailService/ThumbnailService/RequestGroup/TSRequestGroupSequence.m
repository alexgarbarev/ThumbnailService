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
}

- (id)init
{
    self = [super init];
    if (self) {
        sequence = [NSMutableArray new];
    }
    return self;
}

- (void) addRequestSequence:(NSArray *)requests
{
    [sequence addObjectsFromArray:requests];
}

- (NSArray *) pullPendingRequests
{
    NSArray *requests = nil;

    if ([sequence count] > 0) {
        TSRequest *request = [sequence objectAtIndex:0];
        [sequence removeObjectAtIndex:0];
        requests = @[request];
    }
    
    return requests;
}

- (void) didFinishRequest:(TSRequest *)request
{
    [sequence removeObject:request];
}

- (void) didCancelRequest:(TSRequest *)request
{
    [sequence removeAllObjects];
}

@end
