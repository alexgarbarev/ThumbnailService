//
//  TSSource.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSource.h"

@implementation TSSource

- (UIImage *)placeholder
{
    NSAssert(NO, @"Must override");
    return nil;
}

- (UIImage *)thumbnailWithSize:(CGSize)__unused size isCancelled:(const BOOL *)__unused isCancelled error:(NSError *__autoreleasing *)__unused error
{
    NSAssert(NO, @"Must override");
    return nil;
}

- (BOOL)requiresMainThread
{
    return NO;
}

@end
