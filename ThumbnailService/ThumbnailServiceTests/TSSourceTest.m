//
//  TSSourceTest.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 11.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourceTest.h"

@implementation TSSourceTest

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
    return [UIImage new];
}

@end
