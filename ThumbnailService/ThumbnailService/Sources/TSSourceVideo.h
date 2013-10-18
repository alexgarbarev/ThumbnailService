//
//  TSSourceVideo.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 18.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//
#import "TSSource.h"
#import <AVFoundation/AVFoundation.h>

@interface TSSourceVideo : TSSource

- (id) initWithVideoFilePath:(NSString *)filePath thumbnailSecond:(CGFloat)second;
- (id) initWithVideoURL:(NSURL *)url thumbnailSecond:(CGFloat)second;

- (double) videoDuration;

@end
