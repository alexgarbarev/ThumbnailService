//
//  TSSourceTest.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 11.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourceTest.h"

@implementation TSSourceTest {
    dispatch_semaphore_t semaphore;
}

- (id)init
{
    self = [super init];
    if (self) {
        semaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (NSString *) identifier
{
    return @"test";
}

- (UIImage *) placeholder
{
    return [UIImage new];
}

- (UIImage *) thumbnailWithSize:(CGSize)size
{
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return [UIImage new];
}

- (void) fire
{
    dispatch_semaphore_signal(semaphore);
}

@end
