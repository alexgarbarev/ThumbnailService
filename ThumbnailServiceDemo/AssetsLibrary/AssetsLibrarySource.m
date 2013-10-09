//
//  PhotoLibraryDataSource.m
//  PixMarx
//
//  Created by Aleksey Garbarev on 02.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "AssetsLibrarySource.h"
#import "NSArray+RangeCheck.h"
#import "UIImage+Decompress.h"
#import "NotificationUtils.h"
#import "ALAsset+Identifier.h"
#import <ImageIO/ImageIO.h>

NSString *AssetsLibrarySourceChangedNotification = @"AssetsLibrarySourceChangedNotification";
NSString *AssetsLibrarySourceWillReloadNotification = @"AssetsLibrarySourceWillReloadNotification";
NSString *AssetsLibrarySourceDidReloadNotification = @"AssetsLibrarySourceDidReloadNotification";

@implementation AssetsLibrarySource {
    ALAssetsLibrary *assetsLibrary;
    NSArray *assets;
    NSMutableArray *loadingAssets;
    
    dispatch_group_t reloadingGroup;
    dispatch_queue_t reloadingQueue;
}

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

- (void) setup
{
    self.shouldReloadWhenChanged = YES;
    self.filterType = AssetsLibrarySourceTypeAllPhotos;
    self.groups = AssetsLibraryGroupAll;
    
    reloadingGroup = dispatch_group_create();
    reloadingQueue = dispatch_queue_create("reloading_queue", DISPATCH_QUEUE_SERIAL);
    
    assetsLibrary = [[self class] defaultAssetsLibrary];
    
    [self reload];
    
    [self registerForNotification:ALAssetsLibraryChangedNotification selector:@selector(didLibraryChanged:)];
}

- (id) init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) dealloc
{
    [self unregisterForNotification:ALAssetsLibraryChangedNotification];
}

- (void) didLibraryChanged:(NSNotification *)notification
{
    [NSNotificationCenter postNotificationToMainThread:AssetsLibrarySourceChangedNotification];
    
    if (self.shouldReloadWhenChanged) {
        [self reload];
    }
}

- (ALAssetsFilter *) currentFilter
{
    switch (self.filterType) {
        default:
        case AssetsLibrarySourceTypeAll:
            return [ALAssetsFilter allAssets];
        case AssetsLibrarySourceTypeAllPhotos:
            return [ALAssetsFilter allPhotos];
        case AssetsLibrarySourceTypeAllVideos:
            return [ALAssetsFilter allVideos];
    }
}

- (void) setFilterBlock:(AssetsLibraryFilterBlock)filterBlock
{
    _filterBlock = filterBlock;
    [self reloadWithFilterBlock:_filterBlock onQueue:reloadingQueue];
}

- (void) reload
{
    [self reloadWithFilterBlock:_filterBlock onQueue:dispatch_get_main_queue()];
}

- (void) reloadWithFilterBlock:(AssetsLibraryFilterBlock)filterBlock onQueue:(dispatch_queue_t)queue
{
    if ([self isLoading]) {
        [self notifyCompleteOnQueue:queue loadingWithBlock:^{
            [self reloadWithFilterBlock:filterBlock onQueue:queue];
        }];
    }
    else {
        
        [self beginLoading];
        
        dispatch_async(queue, ^{
            ALAssetsFilter *filter = [self currentFilter];
            
            [assetsLibrary enumerateGroupsWithTypes:self.groups usingBlock:^(ALAssetsGroup *group, BOOL *stop)
             {
                 if (group) {
                     [group setAssetsFilter:filter];
                     [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop)
                      {
                          if (!asset) {
                              *stop = YES;
                          } else {
                              BOOL shouldAddAsset = !filterBlock || filterBlock(asset);
                              if (shouldAddAsset) {
                                  [self addAsset:asset];
                              }
                          }
                      }];
                 }
                 else {
                     *stop = YES;
                     [self endLoadingWithError:nil];
                 }
                 
             } failureBlock:^(NSError *error) {
                 [self endLoadingWithError:error];
             }];
        });
    }
}

- (ALAsset *) assetFromURL:(NSURL *)assetURL
{
    __block ALAsset *result = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            result = asset;
            dispatch_semaphore_signal(semaphore);
        } failureBlock:^(NSError *error) {
            NSLog(@"Error while fetch asset: %@",error);
            dispatch_semaphore_signal(semaphore);
        }];
    });

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return result;
}

- (void) saveImageToLibrary:(UIImage *)image withCompletion:(void(^)(NSURL *assetURL))completion
{
    [assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        if (completion) {
            completion(assetURL);
        }
    }];
}

#pragma mark -

- (void) beginLoading
{
    [NSNotificationCenter postNotificationToMainThread:AssetsLibrarySourceWillReloadNotification];
    
    loadingAssets = [NSMutableArray new];
    
    dispatch_group_enter(reloadingGroup);
}

- (void) addAsset:(ALAsset *)asset
{
    [asset identifier];
    [loadingAssets addObject:asset];
}

- (void) endLoadingWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        assets = loadingAssets;
        loadingAssets = nil;
        
        dispatch_group_leave(reloadingGroup);
        
        [NSNotificationCenter postNotificationToMainThread:AssetsLibrarySourceDidReloadNotification];
    });
}

- (BOOL) isLoading
{
    return loadingAssets != nil;
}

- (void) notifyCompleteOnQueue:(dispatch_queue_t)queue loadingWithBlock:(dispatch_block_t)block
{
    dispatch_group_notify(reloadingGroup, queue, block);
}

#pragma mark - Assets enumerations

- (ALAsset *) assetForIndex:(NSUInteger)index
{
    if ([assets containsIndex:index]) {
        return assets[index];
    } else {
        return nil;
    }
}

- (NSUInteger) indexForAsset:(ALAsset *)asset
{
    if (!assets) {
        return NSNotFound;
    } else {
        return [assets indexOfObject:asset];
    }
}

- (NSUInteger) count
{
    return [assets count];
}

- (NSArray *) allAssets
{
    return assets;
}

#pragma mark - Images

- (UIImage *) imageToDisplayAsset:(ALAsset *)asset
{
    return [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
}

- (UIImage *) imageForAsset:(ALAsset *)asset
{
    UIImageOrientation orientation = (UIImageOrientation)[[asset defaultRepresentation] orientation];
    return [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage] scale:1.0f orientation:orientation];
}

- (UIImage *) imageThumbnailForAsset:(ALAsset *)asset andType:(AssetsLibraryThumbnailType)thumbType
{
    CGImageRef thumbnail = NULL;
    if (thumbType == AssetsLibraryThumbnailTypeAspectRatio) {
        thumbnail = [asset aspectRatioThumbnail];
    } else {
        thumbnail = [asset thumbnail];
    }
    return [UIImage imageWithCGImage:thumbnail];
}

- (UIImage *) imageThumbnailForAsset:(ALAsset *)asset andSize:(NSUInteger)size
{
    NSParameterAssert(asset != nil);
    NSParameterAssert(size > 0);
    
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    
    CGDataProviderDirectCallbacks callbacks = {
        .version = 0,
        .getBytePointer = NULL,
        .releaseBytePointer = NULL,
        .getBytesAtPosition = getAssetBytesCallback,
        .releaseInfo = releaseAssetCallback,
    };
    
    CGDataProviderRef provider = CGDataProviderCreateDirect((void *)CFBridgingRetain(rep), [rep size], &callbacks);
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    
    NSDictionary *options = @{ (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                               (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(size),
                               (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                               (NSString *)kCGImageSourceShouldCache : @NO
                              };
    
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);
    CFRelease(provider);
    
    if (!imageRef) {
        return nil;
    }
    
    UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
    
    CFRelease(imageRef);
    
    return toReturn;
}

static size_t getAssetBytesCallback(void *info, void *buffer, off_t position, size_t count) {
    ALAssetRepresentation *rep = (__bridge id)info;
    
    NSError *error = nil;
    size_t countRead = [rep getBytes:(uint8_t *)buffer fromOffset:position length:count error:&error];
    
    if (countRead == 0 && error) {
        // We have no way of passing this info back to the caller, so we log it, at least.
        NSLog(@"thumbnailForAsset:maxPixelSize: got an error reading an asset: %@", error);
    }
    
    return countRead;
}

static void releaseAssetCallback(void *info)
{
    CFRelease(info);
}

@end
