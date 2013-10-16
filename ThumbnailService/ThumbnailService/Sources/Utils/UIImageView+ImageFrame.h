//
//  UIImageView+ImageFrame.h
//  PixMarx
//
//  Created by Aleksey Garbarev on 01.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (ImageFrame)

- (CGRect) imageFrame;

- (CGPoint) imageScales;

+ (CGRect) imageFrameForImageSize:(CGSize)imageSize boundingRect:(CGRect)boundingRect contentMode:(UIViewContentMode)contentMode;
+ (CGPoint) imageScalesForImageSize:(CGSize)imageSize boundingRect:(CGRect)boundingRect contentMode:(UIViewContentMode)contentMode;

@end
