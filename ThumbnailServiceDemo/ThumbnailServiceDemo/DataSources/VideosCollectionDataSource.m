//
//  VideosCollectionDataSource.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 18.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "VideosCollectionDataSource.h"
#import "PreviewCollectionCell.h"
#import <ThumbnailService/ThumbnailService.h>

@implementation VideosCollectionDataSource {
    ThumbnailService *thumbnailService;
    NSArray *videoURLs;
}

- (id) init
{
    self = [super init];
    if (self) {
        thumbnailService = [ThumbnailService new];
        
        videoURLs = @[@"http://www.cybertechmedia.com/samples/billmcguire.mov"];
    }
    return self;
}

- (void)setShouldPrecache:(BOOL)_shouldPrecache
{

}

- (void)setUseMemoryCache:(BOOL)_useMemoryCache
{
    thumbnailService.useMemoryCache = _useMemoryCache;
}

- (void) setUseFileCache:(BOOL)_useFileCache
{
    thumbnailService.useFileCache = _useFileCache;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [videoURLs count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionCell *viewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionCell" forIndexPath:indexPath];
    
    if (viewCell.context) {
        TSRequest *lastRequest = viewCell.context;
        [lastRequest cancel];
    }
    viewCell.imageView.image = nil;
    
    NSURL *videoURL = [[NSURL alloc] initWithString:videoURLs[[indexPath item]]];

    
    TSRequest *request = [TSRequest new];
    request.source = [[TSSourceVideo alloc] initWithVideoURL:videoURL thumbnailSecond:10];
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
    
    [thumbnailService enqueueRequest:request];
    
    [request waitPlaceholder];
    
    viewCell.context = request;
    
    return viewCell;
    
}


@end
