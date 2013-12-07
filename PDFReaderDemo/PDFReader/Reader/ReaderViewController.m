//
//  ReaderViewController.m
//  PDFReader
//
//  Created by Sovelu on 26.11.13.
//  Copyright (c) 2013 Sovelu. All rights reserved.
//

#import "ReaderViewController.h"
#import "PageViewController.h"
#import "AppDelegate.h"

#import <ThumbnailService/ThumbnailService.h>

@interface ReaderViewController () <ScrollingViewControllerDataSource, ScrollingViewControllerDelegate>
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSArray *pages; /* Array of UIViewControllers */

@end

@implementation ReaderViewController
{
    CGPDFDocumentRef document;
    ThumbnailService *thumbnailService;
    CGSize previewLowQualitylSize;
    CGSize previewHighQualitySize;
    NSInteger currentIndex;
}

- (id) initWithPdfPath:(NSString *)filepath
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        thumbnailService = [AppDelegate sharedDelegate].thumbnailService;

        previewLowQualitylSize = CGSizeMake(150, 150);
        previewHighQualitySize = CGSizeMake(320, 480);
        
        self.dataSource = self;
        self.delegate = self;
        
        self.path = filepath;
        
        NSURL * url = [[NSURL alloc]initFileURLWithPath:self.path];
        document = CGPDFDocumentCreateWithURL((CFURLRef)url);
        NSUInteger numberOfPages = CGPDFDocumentGetNumberOfPages(document);
        NSMutableArray *mutablePages = [[NSMutableArray alloc] initWithCapacity:numberOfPages];
        for (int i = 1; i <= numberOfPages; i++) {
            CGPDFPageRef page = CGPDFDocumentGetPage(document, i);
            PageViewController *pageVC = [[PageViewController alloc] initWithPDFPage:page documentName:[self.path lastPathComponent]];
            pageVC.thumbnailService = thumbnailService;
            pageVC.previewLowQualitylSize = previewLowQualitylSize;
            pageVC.previewHighQualitySize = previewHighQualitySize;
            [mutablePages addObject:pageVC];
        }
        self.pages = mutablePages;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    NSArray *sizesToPrecache = @[[NSValue valueWithCGSize:previewLowQualitylSize], [NSValue valueWithCGSize:previewHighQualitySize]];
    [self precachePreviewsForDocument:document documentName:[self.path lastPathComponent] previewSizes:sizesToPrecache];
}

#pragma mark - Preview Precaching

- (void) precachePreviewsForDocument:(CGPDFDocumentRef)_document documentName:(NSString *)documentName previewSizes:(NSArray *)sizes
{
    CFAbsoluteTime timeWhenStart = CFAbsoluteTimeGetCurrent();
    
    NSUInteger numberOfPages = CGPDFDocumentGetNumberOfPages(_document);

    __block NSInteger sizesCount = [sizes count];
    NSInteger *pendingCount;
    pendingCount = malloc(sizeof(NSInteger)*sizesCount);
    
    for (int i = 0; i < sizesCount; i++) {
        pendingCount[i] = numberOfPages;
    }
    
    void(^decrementAtIndex)(NSInteger) = ^(NSInteger index){
        pendingCount[index] -= 1;
       
        if (pendingCount[index] == 0) {
            NSLog(@"All pages precached for size %@ (%g sec)",NSStringFromCGSize([sizes[index] CGSizeValue]), CFAbsoluteTimeGetCurrent() - timeWhenStart);
            sizesCount -= 1;
        }
        
        if (sizesCount == 0) {
            NSLog(@"All %d pages precached for all sizes for '%@' (%g sec)",numberOfPages, documentName, CFAbsoluteTimeGetCurrent() - timeWhenStart);
            free(pendingCount);
        }
    };
    
    for (int i = 1; i <= numberOfPages; i++) {

        [sizes enumerateObjectsUsingBlock:^(NSValue *sizeValue, NSUInteger idx, BOOL *stop) {
            CGPDFPageRef page = CGPDFDocumentGetPage(_document, i);
            TSSourcePDFPage *pdfSource = [[TSSourcePDFPage alloc] initWithPdfPage:page documentName:documentName];
            TSRequest *request = [[TSRequest alloc] init];
            request.source = pdfSource;
            request.size = [sizeValue CGSizeValue];
            request.queuePriority = TSRequestQueuePriorityLow;
            request.shouldCacheInMemory = NO;
            request.shouldCastCompletionsToMainThread = NO;
            [request setThumbnailCompletion:^(UIImage *result, NSError *error) {
                decrementAtIndex(idx);
            }];
            
            if ([thumbnailService hasDiskCacheForRequest:request]) {
                decrementAtIndex(idx);
            } else {
                [thumbnailService enqueueRequest:request];
            }
        }];
    }
    
    NSLog(@"Proactive caching started for '%@'", documentName);
}


#pragma mark - ScrollingViewControllerDataSource

- (NSInteger) numberOfViewControllersForScrollingController:(ScrollViewController *)scrollingController
{
    return [self.pages count];
}

- (UIViewController *) scrollingController:(ScrollViewController *)_controller viewControllerAtIndex:(NSInteger)index
{
    return self.pages[index];
}

#pragma mark - ScrollingViewControllerDelegate

- (void) scrollingController:(ScrollViewController *)controller didChangeVisiblePagesIndecies:(NSIndexSet *)visibleIndecies
{
    NSInteger leftIndex = [visibleIndecies firstIndex] - 1;
    NSInteger rightIndex = [visibleIndecies lastIndex] + 1;

    if (leftIndex >= 0) {
        PageViewController *page = self.pages[leftIndex];
        [page resetZoom];
    }
    
    if (rightIndex <= [self.pages count] - 1) {
        PageViewController *page = self.pages[rightIndex];
        [page resetZoom];
    }
}

@end
