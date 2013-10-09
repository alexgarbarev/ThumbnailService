//
//  ALAsset+Images.h
//  PixMarx
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

typedef NS_ENUM(NSInteger, AssetThumbnailType)
{
    AssetThumbnailTypeRect,
    AssetThumbnailTypeAspectRatio
};

@interface ALAsset (Images)

- (UIImage *) imageToDisplay;
- (UIImage *) image; /* Full resolution */
- (UIImage *) thumbnailWithType:(AssetThumbnailType)thumbType;
- (UIImage *) thumbnailWithSize:(NSUInteger)size;

@end
