//
//  ThumbnailService.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRequest.h"

@interface ThumbnailService : NSObject

@property (nonatomic) BOOL shouldCachePlaceholders; /* Default: NO */

- (void) performRequest:(TSRequest *)request;

- (void) performRequestOnCurrentThread:(TSRequest *)request;

@end
