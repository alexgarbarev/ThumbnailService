//
//  TSLoadOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSLoadOperation.h"
#import <pthread.h>

@implementation TSLoadOperation {
    TSFileCache *cache;
    NSString *key;
}

- (id) initWithKey:(NSString *)_key andFileCache:(TSFileCache *)_fileCache
{
    self = [super init];
    if (self) {
        key = _key;
        cache = _fileCache;
    }
    return self;
}

- (void)main
{
    @autoreleasepool {
        if (![self isCancelled]) {
            self.result = [cache objectForKey:key];
        }
    
        if (![self isCancelled]) {
            for (int i = 0; i < 10; i++)
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
