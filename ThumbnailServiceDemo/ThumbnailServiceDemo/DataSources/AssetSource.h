//
//  AssetSource.h
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSource.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface AssetSource : TSSource

- (id) initWithAsset:(ALAsset *)asset;

@end
