//
//  UIImage+Decompress.m
//  PixMarx
//
//  Created by Aleksey Garbarev on 02.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "UIImage+Decompress.h"

@implementation UIImage (Decompress)

- (void) decompress
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), YES, 1.0f);
    [self drawInRect:CGRectMake(0, 0, 1, 1)];
    UIGraphicsEndImageContext();
}

- (size_t) decompressedMemorySize
{
    return CGImageGetBytesPerRow(self.CGImage) * CGImageGetHeight(self.CGImage);
}

@end
