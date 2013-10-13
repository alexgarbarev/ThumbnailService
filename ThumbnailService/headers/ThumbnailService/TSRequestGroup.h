//
//  TSRequestsGroup.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 13.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRequest.h"

@interface TSRequestGroup : NSObject

/* Calls each time when request from this group has finished. 
   It's a normal to return nil, if you want to wait until more tasks finished  */
- (NSArray *) pullPendingRequests;

- (void) didFinishRequest:(TSRequest *)request;
- (void) didCancelRequest:(TSRequest *)request;

- (BOOL) shouldPerformOnMainQueueRequest:(TSRequest *)request;

- (void) cancel;

@end
