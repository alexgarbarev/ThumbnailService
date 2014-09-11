//
//  UIImageView+ImageFrame.m
//  PixMarx
//
//  Created by Aleksey Garbarev on 01.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "UIImageView+ImageFrame.h"

@implementation UIImageView (ImageFrame)

- (CGRect)imageFrame
{
    return [[self class] imageFrameForImageSize:self.image.size boundingRect:self.bounds contentMode:self.contentMode];
}

- (CGPoint)imageScales
{
    return [[self class] imageScalesForImageSize:self.image.size boundingRect:self.bounds contentMode:self.contentMode];
}

+ (CGRect)imageFrameForImageSize:(CGSize)imageSize boundingRect:(CGRect)boundingRect contentMode:(UIViewContentMode)contentMode
{
    CGRect imageFrame;

    CGPoint scales = [self imageScalesForImageSize:imageSize boundingRect:boundingRect contentMode:contentMode];

    imageFrame.size.width = imageSize.width * scales.x;
    imageFrame.size.height = imageSize.height * scales.y;

    CGPoint center;
    center.x = (boundingRect.size.width - imageFrame.size.width) * 0.5f;
    center.y = (boundingRect.size.height - imageFrame.size.height) * 0.5f;

    CGFloat top = 0;
    CGFloat left = 0;
    CGFloat right = boundingRect.size.width - imageFrame.size.width;
    CGFloat bottom = boundingRect.size.height - imageFrame.size.height;

    switch (contentMode) {
        case UIViewContentModeRedraw:
        case UIViewContentModeCenter:
        case UIViewContentModeScaleAspectFill:
        case UIViewContentModeScaleAspectFit:
        case UIViewContentModeScaleToFill:
            imageFrame.origin = center;
            break;
        case UIViewContentModeTop:
            imageFrame.origin.y = 0;
            imageFrame.origin.x = center.x;
            break;
        case UIViewContentModeTopLeft:
            imageFrame.origin.y = top;
            imageFrame.origin.x = left;
            break;
        case UIViewContentModeTopRight:
            imageFrame.origin.y = top;
            imageFrame.origin.x = right;
            break;
        case UIViewContentModeBottom:
            imageFrame.origin.y = bottom;
            imageFrame.origin.x = center.x;
            break;
        case UIViewContentModeBottomLeft:
            imageFrame.origin.y = bottom;
            imageFrame.origin.x = left;
            break;
        case UIViewContentModeBottomRight:
            imageFrame.origin.y = bottom;
            imageFrame.origin.x = right;
            break;
        case UIViewContentModeLeft:
            imageFrame.origin.y = center.y;
            imageFrame.origin.x = left;
            break;
        case UIViewContentModeRight:
            imageFrame.origin.y = center.y;
            imageFrame.origin.x = right;
            break;
    }

    return imageFrame;
}

+ (CGPoint)imageScalesForImageSize:(CGSize)imageSize boundingRect:(CGRect)boundingRect contentMode:(UIViewContentMode)contentMode
{
    CGPoint scales = CGPointMake(boundingRect.size.width / imageSize.width, boundingRect.size.height / imageSize.height);
    CGPoint resultScales;

    switch (contentMode) {
        case UIViewContentModeScaleAspectFit: {
            CGFloat scale = fminf(scales.x, scales.y);
            resultScales = CGPointMake(scale, scale);
            break;
        }
        case UIViewContentModeScaleAspectFill: {
            CGFloat scale = fmaxf(scales.x, scales.y);
            resultScales = CGPointMake(scale, scale);
            break;
        }
        case UIViewContentModeScaleToFill:
            resultScales = scales;
            break;
        default:
            resultScales = CGPointMake(1.0f, 1.0f);
            break;
    }

    return resultScales;
}

@end
