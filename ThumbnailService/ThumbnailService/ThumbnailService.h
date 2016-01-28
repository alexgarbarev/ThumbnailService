//
//  ThumbnailService.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSCacheManager.h"
#import "TSRequest.h"
#import "TSRequestGroupSequence.h"

@interface ThumbnailService : NSObject

@property (nonatomic) BOOL shouldCachePlaceholders; /* Default: NO */

@property (nonatomic) BOOL useMemoryCache; /* Default: YES */
@property (nonatomic) BOOL useFileCache;   /* Default: YES */
@property (nonatomic) NSUInteger cacheMemoryLimitInBytes; /* Default: 3MB. 0 - unlimited */

/** Add request to internal queue and executes asynchronously */
- (void)enqueueRequest:(TSRequest *)request;

/** Add group of requests to internal queue and executes asynchronously */
- (void)enqueueRequestGroup:(TSRequestGroup *)group;

/** Executes request synchronously on calling thread */
- (void)executeRequest:(TSRequest *)request;

- (BOOL)hasDiskCacheForRequest:(TSRequest *)request;
- (BOOL)hasMemoryCacheForRequest:(TSRequest *)request;

/** Caches name affect to file caches directory. Use context-based name to have ability to clean caches separately per context */
- (void)setCachesName:(NSString *)cachesName;
- (void)clearFileCache;

@end

@interface ThumbnailService (ExtendedApi)

@property (nonatomic, readonly) TSCacheManager *placeholderCache;
@property (nonatomic, readonly) TSCacheManager *thumbnailsCache;

@end
