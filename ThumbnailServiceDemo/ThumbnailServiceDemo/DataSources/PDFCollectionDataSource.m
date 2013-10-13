//
//  PDFCollectionDataSource.m
//  ThumbnailServiceDemo
//
//  Created by Sovelu on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "PDFCollectionDataSource.h"
#import "ThumbnailService.h"
#import "PreviewCollectionCell.h"
#import "TSSourcePdfPage.h"
#import "TSRequestGroupSequence.h"

static CGSize kSmallThumbnailSize = (CGSize){144, 144};

@implementation PDFCollectionDataSource {
    CGPDFDocumentRef document;
    ThumbnailService *thumbnailService;
    NSString *documentName;
}

- (id) init
{
    self = [super init];
    if (self) {
        documentName = @"sample";
        NSURL *documentURL = [[NSBundle mainBundle] URLForResource:documentName withExtension:@"pdf"];
        document = CGPDFDocumentCreateWithURL((__bridge CFURLRef)documentURL);
        
        thumbnailService = [ThumbnailService new];
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
    CFAbsoluteTime timeBeforePrecache = CFAbsoluteTimeGetCurrent();
    
    NSUInteger pagesCount = CGPDFDocumentGetNumberOfPages(document);
    __block NSUInteger pendingPrecache = pagesCount;
    
    for (NSInteger i = 1; i < pagesCount; i++) {
        TSRequest *request = [TSRequest new];
        
        
        TSSourcePdfPage *pageSource = [[TSSourcePdfPage alloc] initWithPdfPage:CGPDFDocumentGetPage(document, i) documentName:documentName];
        request.source = pageSource;
        request.size = kSmallThumbnailSize;
        request.priority = NSOperationQueuePriorityVeryLow;
        [request setThumbnailCompletion:^(UIImage *result, NSError *error) {
            pendingPrecache--;
            if (pendingPrecache == 0) {
                NSLog(@"all pdf pages precached for %g sec",CFAbsoluteTimeGetCurrent()-timeBeforePrecache);
            }
        }];
        [thumbnailService performRequest:request];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return CGPDFDocumentGetNumberOfPages(document);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionCell *viewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionCell" forIndexPath:indexPath];
    
    if (viewCell.context) {
        TSRequestGroup *group = viewCell.context;
        [group cancel];
        viewCell.imageView.image = nil;
    }
    
    CGPDFPageRef page = CGPDFDocumentGetPage(document, [indexPath item]+1);
    
    TSSourcePdfPage *pageSource = [[TSSourcePdfPage alloc] initWithPdfPage:page documentName:documentName];
    pageSource.contentMode = UIViewContentModeScaleAspectFit;
    
    TSRequestGroupSequence *group = [TSRequestGroupSequence new];
    
    TSRequest *smallThumbRequest = [TSRequest new];
    smallThumbRequest.source = pageSource;
    smallThumbRequest.size = kSmallThumbnailSize;
    smallThumbRequest.priority = NSOperationQueuePriorityVeryHigh;
    [smallThumbRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
    }];
    
    TSRequest *bigThumbRequest = [TSRequest new];
    bigThumbRequest.source = pageSource;
    bigThumbRequest.size = kThumbSize;
    bigThumbRequest.priority = NSOperationQueuePriorityVeryHigh;
    
    [bigThumbRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
    }];
    
    [group addRequest:smallThumbRequest runOnMainThread:NO];
    [group addRequest:bigThumbRequest runOnMainThread:NO];
    
    [thumbnailService performRequestGroup:group];
    
    viewCell.context = group;
    
    return viewCell;
}

@end
