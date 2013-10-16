//
//  TSCacheManager.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 11.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSCacheManager.h"
#import "TSFileCache.h"

@implementation TSCacheManager {
    NSCache *memoryCache;
    TSFileCache *fileCache;
}

- (id)init
{
    self = [super init];
    if (self) {
        memoryCache = [NSCache new];
        fileCache = [TSFileCache new];
        fileCache.shouldWriteAsynchronically = YES;
    }
    return self;
}

- (void)setMemoryLimitInBytes:(NSUInteger)memoryLimitInBytes
{
    memoryCache.totalCostLimit = memoryLimitInBytes;
}

- (NSUInteger)memoryLimitInBytes
{
    return memoryCache.totalCostLimit;
}

- (TSFileCache *)fileCache
{
    return fileCache;
}

- (NSCache *)memoryCache
{
    return memoryCache;
}

- (void)setName:(NSString *)n
{
    memoryCache.name = n;
    fileCache.name = n;
}

- (NSString *)name
{
    return memoryCache.name;
}

- (BOOL) objectExistsForKey:(id)key mode:(TSCacheManagerMode)mode
{
    if (mode == 0) {
        return NO;
    }
    
    BOOL exists = YES;
    
    if (mode & TSCacheManagerModeMemory) {
        exists &= [memoryCache objectForKey:key] != nil;
    }
    if (mode & TSCacheManagerModeFile) {
        exists &= [fileCache objectExistsForKey:key];
    }
    
    return exists;
}

- (id)objectForKey:(id)key mode:(TSCacheManagerMode)mode
{
    id object = nil;
    
    if (mode & TSCacheManagerModeMemory) {
        object = [memoryCache objectForKey:key];
    }
    
    if (mode & TSCacheManagerModeFile && !object)
    {
        object = [fileCache objectForKey:key];
        
        if (object && mode & TSCacheManagerModeMemory) {
            [memoryCache setObject:object forKey:key];
        }
    }
    
    return object;
}

- (NSUInteger) decompressedSizeForImage:(UIImage *)image
{
    return CGImageGetBytesPerRow(image.CGImage) * CGImageGetHeight(image.CGImage);
}

- (void)setObject:(id)obj forKey:(id)key mode:(TSCacheManagerMode)mode
{
    NSUInteger cost = 0;
    if ([obj isKindOfClass:[UIImage class]]) {
        cost = [self decompressedSizeForImage:obj];
    }
    
    [self setObject:obj forKey:key cost:cost mode:mode];
}

- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g mode:(TSCacheManagerMode)mode
{
    if (mode & TSCacheManagerModeMemory) {
        [memoryCache setObject:obj forKey:key cost:g];
    }
    if (mode & TSCacheManagerModeFile) {
        [fileCache setObject:obj forKey:key cost:g];
    }
}

- (void)removeObjectForKey:(id)key mode:(TSCacheManagerMode)mode
{
    if (mode & TSCacheManagerModeMemory) {
        [memoryCache removeObjectForKey:key];
    }
    if (mode & TSCacheManagerModeFile) {
        [fileCache removeObjectForKey:key];
    }
}

- (void)removeAllObjectsForMode:(TSCacheManagerMode)mode
{
    if (mode & TSCacheManagerModeMemory) {
        [memoryCache removeAllObjects];
    }
    if (mode & TSCacheManagerModeFile) {
        [fileCache removeAllObjects];
    }
}

@end
