//
//  AssetSource.h
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSource.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>


@interface TSSourceALAsset : TSSource

- (id) initWithAsset:(ALAsset *)asset;

- (BOOL) isPhoto;

- (BOOL) isVideo;
- (double) videoDuration;

@end
