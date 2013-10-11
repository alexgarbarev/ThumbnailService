//
//  TSLoadOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSLoadOperation.h"


@implementation TSLoadOperation {
    TSCacheManager *cache;
    NSString *key;
}

- (id) initWithKey:(NSString *)_key andCacheManager:(TSCacheManager *)_cacheManager;
{
    self = [super init];
    if (self) {
        key = _key;
        cache = _cacheManager;
    }
    return self;
}

- (void)main
{
    @autoreleasepool {
        
        if (![self isCancelled]) {
            self.result = [cache objectForKey:key mode:TSCacheManagerModeFile];
        }
        
        if (!self.result) {
            NSString *description = [NSString stringWithFormat:@"Object for key %@ not found!",key];
            self.error = [NSError errorWithDomain:@"LoadOperation" code:0 userInfo:@{NSLocalizedDescriptionKey:description}];
            return;
        }
        
        if (![self.result isKindOfClass:[UIImage class]]) {
            NSString *description = [NSString stringWithFormat:@"Object for key %@ is %@ is not kind of image!",key, self.result];
            self.error = [NSError errorWithDomain:@"LoadOperation" code:1 userInfo:@{NSLocalizedDescriptionKey:description}];
            self.result = nil;
            return;
        }
    
        if (![self isCancelled]) {
            [self decompressImage:self.result];
        }
        if ([self isCancelled]) {
            self.result = nil;
        }
    }

}

- (void) decompressImage:(UIImage *)image
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), YES, 1.0f);
    [image drawInRect:CGRectMake(0, 0, 1, 1)];
    UIGraphicsEndImageContext();
}

- (void) cancel
{
    self.result = nil;
    [super cancel];
}


@end
