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

#import "ThumbnailService.h"
#import "TSSourceALAsset.h"

@implementation AssetsCollectionDataSource {
    AssetsLibrarySource *source;
    ThumbnailService *thumbnailService;
}

- (id) init
{
    self = [super init];
    if (self) {
        source = [[AssetsLibrarySource alloc] init];
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
    [self startPrecache];
}

- (void) startPrecache
{
    NSArray *allAssets = [source allAssets];
    __block NSUInteger pendingPrecache = [allAssets count];
    CFAbsoluteTime timeBeforePrecache = CFAbsoluteTimeGetCurrent();
    
    for (ALAsset *asset in allAssets) {
        TSRequest *request = [TSRequest new];
        request.source = [[TSSourceALAsset alloc] initWithAsset:asset];
        request.size = kThumbSize;
        request.priority = NSOperationQueuePriorityVeryLow;
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
    
    ALAsset *asset = [source assetForIndex:[indexPath item]];

    TSRequest *request = [TSRequest new];
    request.source = [[TSSourceALAsset alloc] initWithAsset:asset];
    request.size = kThumbSize;
    request.priority = NSOperationQueuePriorityVeryHigh;

    [request setPlaceholderCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
    }];
    
    [request setThumbnailCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
    }];
    
    [thumbnailService performRequest:request];
    
    viewCell.context = request;
    
    return viewCell;
    
}

@end
