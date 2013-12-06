//
//  ThumbnailService+Testing.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 16.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "ThumbnailService.h"

@interface ThumbnailService (Testing)

- (void) enqueueRequest:(TSRequest *)request andWait:(BOOL)wait;
- (void) enqueueRequestGroup:(TSRequestGroup *)group andWait:(BOOL)wait;

@end
