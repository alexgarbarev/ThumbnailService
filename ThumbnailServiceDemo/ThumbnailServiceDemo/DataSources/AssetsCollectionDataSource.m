//
//  AssetsCollectionDataSource.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "AssetsCollectionDataSource.h"
#import "AssetsLibrarySource.h"
#import "ALAsset+Images.h"
#import "PreviewCollectionCell.h"
#import "NotificationUtils.h"

#import "CustomAssetSource.h"

#import <ThumbnailService/ThumbnailService.h>

@implementation AssetsCollectionDataSource {
    AssetsLibrarySource *source;
    ThumbnailService *thumbnailService;
    BOOL shouldPrecache;
}

- (id) init
{
    self = [super init];
    if (self) {
        source = [[AssetsLibrarySource alloc] init];
        source.filterType = AssetsLibrarySourceTypeAll;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetLibraryDidReload) name:AssetsLibrarySourceDidReloadNotification object:nil];
        
        thumbnailService = [ThumbnailService new];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) assetLibraryDidReload
{
    [self.collectionView reloadData];
    if (shouldPrecache) {
        [self startPrecache];
    }

}

- (void) setShouldPrecache:(BOOL)_shouldPrecache
{
    shouldPrecache = _shouldPrecache;
}

- (void)setUseMemoryCache:(BOOL)_useMemoryCache
{
    thumbnailService.useMemoryCache = _useMemoryCache;
}

- (void) setUseFileCache:(BOOL)_useFileCache
{
    thumbnailService.useFileCache = _useFileCache;
}

- (void) startPrecache
{
    NSArray *allAssets = [source allAssets];
    __block NSUInteger pendingPrecache = [allAssets count];
    CFAbsoluteTime timeBeforePrecache = CFAbsoluteTimeGetCurrent();
    
    for (ALAsset *asset in allAssets) {
        TSRequest *request = [TSRequest new];
        request.source = [[CustomAssetSource alloc] initWithAsset:asset];
        request.size = kBigThumbSize;
        request.queuePriority = NSOperationQueuePriorityVeryLow;
        [request setThumbnailCompletion:^(UIImage *result, NSError *error) {
            pendingPrecache--;
            if (pendingPrecache == 0) {
                NSLog(@"all precached for %g sec",CFAbsoluteTimeGetCurrent()-timeBeforePrecache);
            }
        }];
        [thumbnailService performRequest:request];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    self.collectionView = collectionView;
    return [source count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionCell *viewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionCell" forIndexPath:indexPath];
    
    if (viewCell.context) {
        TSRequest *lastRequest = viewCell.context;
        [lastRequest cancel];
    }
    viewCell.imageView.image = nil;
    
    ALAsset *asset = [source assetForIndex:[indexPath item]];

    TSRequest *request = [TSRequest new];
    request.source = [[CustomAssetSource alloc] initWithAsset:asset];
    request.size = kBigThumbSize;
    request.queuePriority = NSOperationQueuePriorityVeryHigh;
    

    [request setPlaceholderCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
        if (!result){
            NSLog(@"placeholder error :%@",error);
        }
    }];
    
    [request setThumbnailCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
        if (!result){
            NSLog(@"thumbnail error :%@",error);
        }

    }];
    
    [thumbnailService performRequest:request];
    
    [request waitPlaceholder];

    viewCell.context = request;
    
    return viewCell;
    
}

@end
