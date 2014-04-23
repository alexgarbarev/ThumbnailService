//
//  TSRequestsGroup.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 13.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequestGroup.h"

@implementation TSRequestGroup

- (NSArray *)pullPendingRequests
{
    return nil;
}

- (void) didFinishRequest:(TSRequest *)__unused request
{
    
}

- (void) didCancelRequest:(TSRequest *)__unused request
{
    
}

- (BOOL) shouldPerformOnMainQueueRequest:(TSRequest *)__unused request
{
    return NO;
}

- (void) cancel
{
    
}

- (void)waitUntilFinished
{
    
}

- (BOOL)isFinished
{
    NSAssert(NO, @"You have to implement this method in subclass");
    return NO;
}

@end
