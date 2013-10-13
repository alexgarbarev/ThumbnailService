//
//  FileCache.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSFileCache.h"

static NSString *kCacheExtensionImage = @"image";
static NSString *kCacheExtensionObject = @"object";

@implementation TSFileCache {
    NSFileManager *fileManager;
    NSString *_cacheDirectory;
    dispatch_queue_t fileCacheQueue;
}

- (id)init
{
    self = [super init];
    if (self) {
        fileManager = [NSFileManager defaultManager];
        [self createCacheDirectory];
        fileCacheQueue = dispatch_queue_create("workQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc
{
    dispatch_release(fileCacheQueue);
}

#pragma mark - NSCache overrides

- (id)objectForKey:(id)key
{
    __block id object = nil;
    
    dispatch_sync(fileCacheQueue, ^{
        
        if (![self objectExistsForKey:key]) {
            return;
        }
        
        NSString *extension = [self pathExtensionForKey:key];
        NSString *path = [self filePathForKey:key extension:extension];
        
        if ([extension isEqualToString:kCacheExtensionImage]) {
            object = [[UIImage alloc] initWithContentsOfFile:path];
        } else if ([extension isEqualToString:kCacheExtensionObject]){
            object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        }

    });
    return object;
}

- (void)setObject:(id)obj forKey:(id)key
{
    [self setObject:obj forKey:key cost:0];
}

- (void)setObject:(id)object forKey:(id)key cost:(NSUInteger)g
{
    dispatch_block_t writeBlock = ^{
        @autoreleasepool {
            NSString *extension;
            NSData *data;
            if ([object isKindOfClass:[UIImage class]]) {
                data = UIImagePNGRepresentation(object);
                extension = kCacheExtensionImage;
            } else {
                data = [NSKeyedArchiver archivedDataWithRootObject:object];
                extension = kCacheExtensionObject;
            }
            NSString *path = [[[self cacheDirectory] stringByAppendingPathComponent:key] stringByAppendingPathExtension:extension];
            [data writeToFile:path options:0 error:nil];
        }
    };
    
    if (self.shouldWriteAsynchronically) {
        dispatch_async(fileCacheQueue, writeBlock);
    } else {
        dispatch_sync(fileCacheQueue, writeBlock);
    }
}

- (void)removeObjectForKey:(id)key
{
    dispatch_sync(fileCacheQueue, ^{
        NSString *path = [self pathForKey:key];
        [fileManager removeItemAtPath:path error:nil];
    });
}

- (void)removeAllObjects
{
    dispatch_sync(fileCacheQueue, ^{
        [fileManager removeItemAtPath:[self cacheDirectory] error:nil];
        [self createCacheDirectory];
    });
}

- (void) setName:(NSString *)n
{
    dispatch_sync(fileCacheQueue, ^{
        [super setName:n];
        [self updateCacheDirectory];
        [self createCacheDirectory];
    });
}

- (NSString *) name
{
    return [super name];
}

#pragma mark -

- (id) objectWithContentsOfPath:(NSString *)path
{
    id object;
    
    if ([[path pathExtension] isEqualToString:kCacheExtensionImage]) {
        object = [UIImage imageWithContentsOfFile:path];
    } else {
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }
    
    return object;
}

#pragma mark - Paths

- (NSString *) filePathForKey:(NSString *)key extension:(NSString *)extension
{
    return [[[self cacheDirectory] stringByAppendingPathComponent:key] stringByAppendingPathExtension:extension];
}

- (NSString *) pathForKey:(NSString *)key
{
    NSString *extension = [self pathExtensionForKey:key];
    return [self filePathForKey:key extension:extension];
}

- (BOOL) objectExistsForKey:(NSString *)key
{
    return [self pathExtensionForKey:key] != nil;
}

- (NSString *) pathExtensionForKey:(NSString *)key
{
    NSString *extension = nil;
    if ([self objectExistsForKey:key andExtension:kCacheExtensionImage]) {
        extension = kCacheExtensionImage;
    } else if ([self objectExistsForKey:key andExtension:kCacheExtensionObject]){
        extension = kCacheExtensionObject;
    }
    return extension;
}

- (BOOL) objectExistsForKey:(NSString *)key andExtension:(NSString *)extension
{
    NSString *path = [[[self cacheDirectory] stringByAppendingPathComponent:key] stringByAppendingPathExtension:extension];
    return [fileManager fileExistsAtPath:path];
}

#pragma mark - Cache Directory

- (void) updateCacheDirectory
{
    NSString *rootCacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    _cacheDirectory = [rootCacheDirectory stringByAppendingPathComponent:[self name]];
}

- (NSString *) cacheDirectory
{
    return _cacheDirectory;
}

- (void) createCacheDirectory
{
    [fileManager createDirectoryAtPath:[self cacheDirectory] withIntermediateDirectories:YES attributes:nil error:nil];
}

#pragma mark - Asserts


- (void)setDelegate:(id <NSCacheDelegate>)d
{
    NSAssert(NO, @"Is not implemented");
}
- (id <NSCacheDelegate>)delegate
{
    return nil;
}
- (void)setTotalCostLimit:(NSUInteger)lim
{
    NSAssert(NO, @"Is not implemented");
}
- (NSUInteger)totalCostLimit
{
    return 0;
}
- (void)setCountLimit:(NSUInteger)lim
{
    NSAssert(NO, @"Is not implemented");
}
- (NSUInteger)countLimit
{
    return 0;
}
- (BOOL)evictsObjectsWithDiscardedContent
{
    return NO;
}
- (void)setEvictsObjectsWithDiscardedContent:(BOOL)b
{
    NSAssert(NO, @"Is not implemented");
}


@end
