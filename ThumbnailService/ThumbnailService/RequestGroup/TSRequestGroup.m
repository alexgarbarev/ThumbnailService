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

- (void) didFinishRequest:(TSRequest *)request
{
    
}

- (void) didCancelRequest:(TSRequest *)request
{
    
}

- (BOOL) shouldPerformOnMainQueueRequest:(TSRequest *)request
{
    return NO;
}

@end
