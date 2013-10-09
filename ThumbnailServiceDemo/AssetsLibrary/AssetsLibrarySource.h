//
//  PhotoLibraryDataSource.h
//  PixMarx
//
//  Created by Aleksey Garbarev on 02.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef NS_ENUM(NSInteger, AssetsLibrarySourceType)
{
    AssetsLibrarySourceTypeAllPhotos,
    AssetsLibrarySourceTypeAllVideos,
    AssetsLibrarySourceTypeAll
};

typedef NS_ENUM(NSInteger, AssetsLibraryThumbnailType)
{
    AssetsLibraryThumbnailTypeRect,
    AssetsLibraryThumbnailTypeAspectRatio
};

typedef NS_ENUM(NSUInteger, AssetsLibraryGroup)
{
    AssetsLibraryGroupLibrary        = (1 << 0),
    AssetsLibraryGrouppAlbum         = (1 << 1),
    AssetsLibraryGroupEvent          = (1 << 2),
    AssetsLibraryGroupFaces          = (1 << 3),
    AssetsLibraryGroupSavedPhotos    = (1 << 4),
    AssetsLibraryGroupPhotoStream    = (1 << 5),
    AssetsLibraryGroupAll            = 0xFFFFFFFF,
};

typedef BOOL(^AssetsLibraryFilterBlock)(ALAsset *asset);

extern NSString *AssetsLibrarySourceChangedNotification;
extern NSString *AssetsLibrarySourceWillReloadNotification;
extern NSString *AssetsLibrarySourceDidReloadNotification;

@interface AssetsLibrarySource : NSObject 

@property (nonatomic) AssetsLibrarySourceType filterType; /* Default: AssetsLibrarySourceTypeAllPhotos */
@property (nonatomic) BOOL shouldReloadWhenChanged;       /* Default: YES */
@property (nonatomic) AssetsLibraryGroup groups;          /* Default: AssetsLibraryGroupAll */

@property (nonatomic, strong) AssetsLibraryFilterBlock filterBlock;

/* Reload assets from ALAssetsLibrary */
- (void) reload;

- (ALAsset *) assetFromURL:(NSURL *)assetURL;
- (void) saveImageToLibrary:(UIImage *)image withCompletion:(void(^)(NSURL *assetURL))completion;

/* Assets enumerations */
- (NSUInteger) count;
- (ALAsset *) assetForIndex:(NSUInteger)index;
- (NSUInteger) indexForAsset:(ALAsset *)asset;

- (NSArray *) allAssets;

/* Images */
- (UIImage *) imageToDisplayAsset:(ALAsset *)asset;
- (UIImage *) imageForAsset:(ALAsset *)asset; /* Full resolution */
- (UIImage *) imageThumbnailForAsset:(ALAsset *)asset andType:(AssetsLibraryThumbnailType)thumbType;
- (UIImage *) imageThumbnailForAsset:(ALAsset *)asset andSize:(NSUInteger)size;

@end

