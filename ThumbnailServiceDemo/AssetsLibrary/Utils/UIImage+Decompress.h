//
//  UIImage+Decompress.h
//  PixMarx
//
//  Created by Aleksey Garbarev on 02.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Decompress)

- (void) decompress;

- (size_t) decompressedMemorySize;

@end
