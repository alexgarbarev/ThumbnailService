//
//  TSCacheManager.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 11.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSFileCache.h"

typedef enum {
    TSCacheManagerModeNone   = 0,
    TSCacheManagerModeMemory = 1 << 0,
    TSCacheManagerModeFile   = 1 << 1,
} TSCacheManagerMode;

static const TSCacheManagerMode TSCacheManagerModeFileAndMemory = TSCacheManagerModeFile | TSCacheManagerModeMemory;

@interface TSCacheManager : NSObject

@property (nonatomic) NSUInteger memoryLimitInBytes;
@property (nonatomic) BOOL shouldWriteAsynchronically;
@property (nonatomic) TSFileCacheImageWriteMode imageWriteMode; /* Default: PNG */
@property (nonatomic) CGFloat imageWriteCompressionQuality; /* Default: 0.6. Used only in TSFileCacheImageWriteModeJPG */

- (void)setName:(NSString *)name;
- (NSString *)name;

- (BOOL)objectExistsForKey:(id)key mode:(TSCacheManagerMode)mode;

- (id)objectForKey:(id)key mode:(TSCacheManagerMode)mode;
- (void)setObject:(id)obj forKey:(id)key mode:(TSCacheManagerMode)mode;
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g mode:(TSCacheManagerMode)mode;
- (void)removeObjectForKey:(id)key mode:(TSCacheManagerMode)mode;

- (void)removeAllObjectsForMode:(TSCacheManagerMode)mode;

@end
