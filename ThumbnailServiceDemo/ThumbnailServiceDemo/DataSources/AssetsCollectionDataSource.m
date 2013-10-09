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

@implementation AssetsCollectionDataSource {
    AssetsLibrarySource *source;
}

- (id) init
{
    self = [super init];
    if (self) {
        source = [[AssetsLibrarySource alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetLibraryDidReload) name:AssetsLibrarySourceDidReloadNotification object:nil];
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
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    self.collectionView = collectionView;
    return [source count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionCell *viewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionCell" forIndexPath:indexPath];
    
    ALAsset *asset = [source assetForIndex:[indexPath item]];
    
    viewCell.imageView.image = [asset thumbnailWithType:AssetThumbnailTypeAspectRatio];

    
    return viewCell;
    
}

@end
