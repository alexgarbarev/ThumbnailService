//
//  ImagesCollectionDataSource.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 17.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "ImagesCollectionDataSource.h"
#import "PreviewCollectionCell.h"

#import <ThumbnailService/ThumbnailService.h>

@implementation ImagesCollectionDataSource {
    ThumbnailService *thumbnailService;
    NSArray *imagePaths;
}

- (id)init
{
    self = [super init];
    if (self) {
        thumbnailService = [[ThumbnailService alloc] init];
        
        imagePaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"png" inDirectory:nil];
        imagePaths = [imagePaths arrayByAddingObjectsFromArray:[[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:nil]];
    }
    return self;
}

- (void)setShouldPrecache:(BOOL)_shouldPrecache
{
    if (_shouldPrecache) {
        [self startPrecache];
    }
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
    [self precachePagesFromIndex:1];
}


- (void) precachePagesFromIndex:(NSInteger)i
{

}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [imagePaths count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionCell *viewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionCell" forIndexPath:indexPath];
    
    if (viewCell.context) {
        TSRequestGroupSequence *group = viewCell.context;
        [group cancel];
        viewCell.imageView.image = nil;
    }
    
    NSString *imagePath = imagePaths[[indexPath item]];
    TSSourceImage *imageSource = [[TSSourceImage alloc] initWithImagePath:imagePath];
    
    TSRequestGroupSequence *group = [TSRequestGroupSequence new];
    
    TSRequest *smallThumbRequest = [TSRequest new];
    smallThumbRequest.source = imageSource;
    smallThumbRequest.size = kSmallThumbnailSize;
    smallThumbRequest.queuePriority = NSOperationQueuePriorityVeryHigh;
    [smallThumbRequest setPlaceholderCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
    }];
    [smallThumbRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
    }];
    
    TSRequest *bigThumbRequest = [TSRequest new];
    bigThumbRequest.source = imageSource;
    bigThumbRequest.size = kBigThumbSize;
    bigThumbRequest.queuePriority = NSOperationQueuePriorityHigh;
    
    [bigThumbRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
    }];
    
    [group addRequest:smallThumbRequest];
    [group addRequest:bigThumbRequest];
    
    [thumbnailService enqueueRequestGroup:group];
    
    
    //    [bigThumbRequest waitUntilFinished];
    
    //    [smallThumbRequest waitPlaceholder];
    //    [smallThumbRequest waitUntilFinished];
    
    viewCell.context = group;
    
    return viewCell;
}

@end
