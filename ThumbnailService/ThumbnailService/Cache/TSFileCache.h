//
//  FileCache.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TSFileCacheImageWriteMode)
{
    TSFileCacheImageWriteModePNG,
    TSFileCacheImageWriteModeJPG,
    TSFileCacheImageWriteModeBase64
};

/* TSFileCache is threaded-safe */

@interface TSFileCache : NSCache

@property (nonatomic) BOOL shouldWriteAsynchronically;

@property (nonatomic) TSFileCacheImageWriteMode imageWriteMode; /* Default: PNG */
@property (nonatomic) CGFloat imageWriteCompressionQuality; /* Default: 0.6. Used only in TSFileCacheImageWriteModeJPG */

- (void)setName:(NSString *)n;
- (NSString *)name;

- (BOOL) objectExistsForKey:(id)key;

- (id)objectForKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key; // 0 cost
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g; // cost is not used
- (void)removeObjectForKey:(id)key;

- (void)removeAllObjects;

/* This class writes object to file instead of keep in memory.
   So, all memory-related properties and methods from NSCache are unavailable */
- (void)setDelegate:(id <NSCacheDelegate>)d UNAVAILABLE_ATTRIBUTE;
- (id <NSCacheDelegate>)delegate UNAVAILABLE_ATTRIBUTE;
- (void)setTotalCostLimit:(NSUInteger)lim UNAVAILABLE_ATTRIBUTE;
- (NSUInteger)totalCostLimit UNAVAILABLE_ATTRIBUTE;
- (void)setCountLimit:(NSUInteger)lim UNAVAILABLE_ATTRIBUTE;
- (NSUInteger)countLimit UNAVAILABLE_ATTRIBUTE;
- (BOOL)evictsObjectsWithDiscardedContent UNAVAILABLE_ATTRIBUTE;
- (void)setEvictsObjectsWithDiscardedContent:(BOOL)b UNAVAILABLE_ATTRIBUTE;

@end