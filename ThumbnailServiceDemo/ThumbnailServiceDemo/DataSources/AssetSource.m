//
//  AssetSource.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "AssetSource.h"
#import "ALAsset+Identifier.h"
#import "ALAsset+Images.h"

@implementation AssetSource {
    ALAsset *asset;
}

- (id) initWithAsset:(ALAsset *)_asset
{
    self = [super init];
    if (self) {
        asset = _asset;
    }
    return self;
}

- (NSString *) identifier
{
    return asset.identifier;
}

- (UIImage *) placeholder
{
    return [asset thumbnailWithType:AssetThumbnailTypeAspectRatio];
}

- (UIImage *) thumbnailWithSize:(CGSize)size
{
    return [asset thumbnailWithSize:MAX(size.width, size.height)];
}

@end
