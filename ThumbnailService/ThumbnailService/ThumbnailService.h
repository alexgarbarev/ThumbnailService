//
//  ThumbnailService.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRequest.h"
#import "TSRequestGroupSequence.h"

@interface ThumbnailService : NSObject

@property (nonatomic) BOOL shouldCachePlaceholders; /* Default: NO */

@property (nonatomic) BOOL useMemoryCache; /* Default: YES */
@property (nonatomic) BOOL useFileCache;   /* Default: YES */
@property (nonatomic) NSUInteger cacheMemoryLimitInBytes; /* Default: 3MB. 0 - unlimited */

- (void) performRequest:(TSRequest *)request;
- (void) performRequest:(TSRequest *)request andWait:(BOOL)wait;

- (void) performRequestGroup:(TSRequestGroup *)group;
- (void) performRequestGroup:(TSRequestGroup *)group andWait:(BOOL)wait;

- (void) clearFileCache;

+ (void) setShouldFailOnWarning:(BOOL)shouldFail;
+ (BOOL) shouldFailOnWarning;

@end
