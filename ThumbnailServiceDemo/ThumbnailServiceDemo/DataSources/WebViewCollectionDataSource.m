//
//  WebViewCollectionDataSource.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 23.04.14.
//  Copyright (c) 2014 Aleksey Garbarev. All rights reserved.
//

#import "WebViewCollectionDataSource.h"
#import "PreviewCollectionCell.h"
#import <ThumbnailService/ThumbnailService.h>

@implementation WebViewCollectionDataSource {
    ThumbnailService *thumbnailService;
}


- (id) init
{
    self = [super init];
    if (self) {
        thumbnailService = [ThumbnailService new];
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
    return 1;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionCell *viewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionCell" forIndexPath:indexPath];
    
    if (viewCell.context) {
        TSRequest *lastRequest = viewCell.context;
        [lastRequest cancel];
    }
    viewCell.imageView.image = nil;
    
    
    TSRequest *request = [TSRequest new];
    request.source = [[TSSourceWebView alloc] initWithUrl:[[NSURL alloc] initWithString:@"https://github.com/"]];
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
