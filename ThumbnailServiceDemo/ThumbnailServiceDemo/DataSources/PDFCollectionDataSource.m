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
#import "TSSourcePDF.h"
#import "TSRequestGroupSequence.h"

@implementation PDFCollectionDataSource {
    CGPDFDocumentRef document;
    ThumbnailService *thumbnailService;
}

- (id) init
{
    self = [super init];
    if (self) {
        NSURL *documentURL = [[NSBundle mainBundle] URLForResource:@"example" withExtension:@"pdf"];
        document = CGPDFDocumentCreateWithURL((__bridge CFURLRef)documentURL);
        
        thumbnailService = [ThumbnailService new];
    }
    return self;
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
    
    CGPDFPageRef page = CGPDFDocumentGetPage(document, [indexPath item]);
    
    TSRequestGroupSequence *group = [TSRequestGroupSequence new];
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    TSRequest *smallThumbRequest = [TSRequest new];
    smallThumbRequest.source = [[TSSourcePDF alloc] initWithPdfPage:page];
    smallThumbRequest.size = CGSizeMake(40 *scale, 40*scale);
    smallThumbRequest.priority = NSOperationQueuePriorityVeryHigh;
    
    [smallThumbRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
        NSAssert([NSThread isMainThread], @"");
        NSLog(@"small received for index %d",[indexPath item]);
        viewCell.imageView.image = result;
    }];
    
    TSRequest *bigThumbRequest = [TSRequest new];
    bigThumbRequest.source = [[TSSourcePDF alloc] initWithPdfPage:page];
    bigThumbRequest.size = CGSizeMake(kThumbSize.width * scale, kThumbSize.height * scale);
    bigThumbRequest.priority = NSOperationQueuePriorityVeryHigh;
    
    [bigThumbRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
        NSAssert([NSThread isMainThread], @"");
        NSLog(@"big received for index %d",[indexPath item]);
//        if ([indexPath item] == 9) {
//            
//        }
        viewCell.imageView.image = result;
    }];
    
    [group addRequest:smallThumbRequest runOnMainThread:YES];
    [group addRequest:bigThumbRequest runOnMainThread:NO];
    
    [thumbnailService performRequestGroup:group ];
    NSLog(@"Cell: %d",[indexPath item]);
    
    viewCell.context = group;
    
    return viewCell;
    
}

@end
