//
//  AssetSource.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourceALAsset.h"
#import "ALAsset+Identifier.h"
#import "ALAsset+Images.h"

@implementation TSSourceALAsset {
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

- (UIImage *) thumbnailWithSize:(CGSize)size isCancelled:(BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    return [asset thumbnailWithSize:MAX(size.width, size.height)];
}

@end
