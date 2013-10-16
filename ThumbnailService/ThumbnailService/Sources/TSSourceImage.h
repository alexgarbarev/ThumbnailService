//
//  TSSourceImage.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 17.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSource.h"
#import <ImageIO/ImageIO.h>

@interface TSSourceImage : TSSource

- (id) initWithImagePath:(NSString *)imagePath;
- (id) initWithImageLocalURL:(NSURL *)imageURL;

@end
