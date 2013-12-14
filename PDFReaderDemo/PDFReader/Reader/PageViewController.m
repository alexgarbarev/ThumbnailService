//
//  PageViewController.m
//  PDFReader
//
//  Created by Sovelu on 26.11.13.
//  Copyright (c) 2013 Sovelu. All rights reserved.
//

#import "PageViewController.h"
#import "PageView.h"
#import "UIImageView+ImageFrame.h"

#import <ThumbnailService/ThumbnailService.h>

@interface ScrollViewCenteredContent : UIScrollView

@end

@implementation ScrollViewCenteredContent

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    UIView *contentView = [self.delegate viewForZoomingInScrollView:self];
    
    CGSize containerSize = self.bounds.size;
    CGRect frame = contentView.frame;

    frame.origin = CGPointZero;
    if (frame.size.width < containerSize.width) {
        frame.origin.x = (containerSize.width - frame.size.width)*0.5f + self.contentOffset.x;
    }
    if (frame.size.height < containerSize.height) {
        frame.origin.y = (containerSize.height - frame.size.height)*0.5f + self.contentOffset.y;
    }
    
    contentView.frame = frame;
}

@end


@class ScrollViewCenteredContent;

@interface PageViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) PageView *pageView;

@property (nonatomic, getter = isPreviewLoaded) BOOL previewLoaded;
@property (nonatomic, getter = isSmallPreviewLoaded) BOOL smallPreviewLoaded;

@property (nonatomic, strong) TSRequest *currentLowRequest;
@property (nonatomic, strong) TSRequest *currentHiRequest;
@end

@implementation PageViewController {
    CGPDFPageRef page;
    NSString *documentName;
    UIView *contentView;
}

- (id) initWithPDFPage:(CGPDFPageRef)pdfPageRef documentName:(NSString *)_documentName
{
    self = [super init];
    if (self) {
        page = CGPDFPageRetain(pdfPageRef);
        documentName = _documentName;
    }
    return self;
}

- (void) dealloc
{
    [self.currentLowRequest cancel];
    [self.currentHiRequest cancel];
    CGPDFPageRelease(page);
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.clipsToBounds = YES;
    contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [contentView addSubview:self.imageView];

    self.scrollView = [[ScrollViewCenteredContent alloc] initWithFrame:self.view.bounds];
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.delegate = self;
    [self.scrollView addSubview:contentView];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 10;
    
    [self.view addSubview:self.scrollView];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleZoom2x:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:doubleTap];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.currentLowRequest cancel];
    [self.currentHiRequest cancel];
    
    self.currentLowRequest = nil;
    self.currentHiRequest = nil;
    
    self.imageView.image = nil;
    self.previewLoaded = NO;
    self.smallPreviewLoaded = NO;
    
    [self.pageView removeFromSuperview];
    self.pageView = nil;
    
    [self resetZoom];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadPreview];
}

- (void) setSmallPreviewLoaded:(BOOL)smallPreviewLoaded
{
    if (smallPreviewLoaded && self.imageView.image) {
        [self lowPreviewDidLoaded];
    }
    _smallPreviewLoaded = smallPreviewLoaded;
}

- (void) setPreviewLoaded:(BOOL)previewLoaded
{
    if (previewLoaded && self.imageView.image) {
        [self hiPreviewDidLoaded];
    }
    _previewLoaded = previewLoaded;
}

- (void) loadPreview
{
    __weak typeof(self) weakSelf = self;
    
    TSSourcePDFPage *pdfPageSource = [[TSSourcePDFPage alloc] initWithPdfPage:page documentName:documentName];
    
    TSRequest *lowRequest = nil;
    TSRequest *hiRequest = nil;
    
    BOOL hasDiskCacheForLowRequest = NO;
    
    BOOL needLoadLowPreview = !self.currentLowRequest && ![self isSmallPreviewLoaded];
    BOOL needLoadHiPreview = !self.currentHiRequest && ![self isPreviewLoaded];
    
    if (needLoadLowPreview) {
        lowRequest = [TSRequest new];
        lowRequest.source = pdfPageSource;
        lowRequest.size = self.previewLowQualitylSize;
        lowRequest.queuePriority = TSRequestQueuePriorityHigh;
        [lowRequest setPlaceholderCompletion:^(UIImage *result, NSError *error) {
            weakSelf.imageView.image = result;
        }];
        
        hasDiskCacheForLowRequest = [self.thumbnailService hasDiskCacheForRequest:lowRequest];
        
        if (!hasDiskCacheForLowRequest) {
            [self.thumbnailService executeRequest:lowRequest];
        }
        
        [lowRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
            weakSelf.imageView.image = result;
            weakSelf.smallPreviewLoaded = YES;
            weakSelf.currentLowRequest = nil;
        }];
    }
    

    if (needLoadHiPreview) {
        hiRequest = [TSRequest new];
        hiRequest.source = pdfPageSource;
        hiRequest.size = self.previewHighQualitySize;
        hiRequest.queuePriority = TSRequestQueuePriorityNormal;

        [hiRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
            weakSelf.imageView.image = result;
            weakSelf.previewLoaded = YES;
            weakSelf.currentHiRequest = nil;
        }];
    }
    
    if (needLoadHiPreview && needLoadLowPreview)
    {
        if (hasDiskCacheForLowRequest) {
            [self.thumbnailService executeRequest:lowRequest];
            [self.thumbnailService enqueueRequest:hiRequest];
        } else {
            TSRequestGroupSequence *group = [TSRequestGroupSequence new];
            [group addRequest:lowRequest];
            [group addRequest:hiRequest];
            [self.thumbnailService enqueueRequestGroup:group];
        }
    }
    else if (needLoadHiPreview)
    {
        [self.thumbnailService enqueueRequest:hiRequest];
    }
    else if (needLoadLowPreview)
    {
        if (hasDiskCacheForLowRequest) {
            [self.thumbnailService executeRequest:lowRequest];
        } else {
            [self.thumbnailService enqueueRequest:lowRequest];
        }
    }
    
    self.currentLowRequest = lowRequest;
    self.currentHiRequest = hiRequest;
}

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return contentView;
}

- (void) scrollViewDidZoom:(UIScrollView *)scrollView
{
    BOOL pageViewShouldBeVisible = scrollView.zoomScale > 1;
    
    if (pageViewShouldBeVisible) {
        [self createPageViewIfNeeded];
    }
    
    self.pageView.hidden = !pageViewShouldBeVisible;
}

- (void) updateScrollViewInsets
{
    CGRect imageFrame = [self.imageView imageFrame];
    contentView.frame = imageFrame;
    
    self.scrollView.contentSize = contentView.bounds.size;
}

- (void) createPageViewIfNeeded
{
    if (!self.pageView) {
        self.pageView = [[PageView alloc] initPDFPage:page];
        self.pageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.pageView.frame = self.imageView.bounds;
        [contentView addSubview:self.pageView];
    }
}

- (void) resetZoom
{
    self.scrollView.contentOffset = CGPointZero;
    self.scrollView.zoomScale = 1;
}

- (void) toggleZoom2x:(UITapGestureRecognizer *)doubleTap
{
    [self createPageViewIfNeeded];
    
    CGFloat targetZoom = self.scrollView.zoomScale > 1 ? 1 : self.scrollView.zoomScale * 2;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.scrollView.zoomScale = targetZoom;
    }];
}

- (void) updateContentViewSize
{
    CGRect contentFrame = [UIImageView imageFrameForImageSize:self.imageView.image.size boundingRect:self.scrollView.bounds contentMode:UIViewContentModeScaleAspectFit];
    contentFrame.origin = CGPointZero;
    contentFrame.size.width *= self.scrollView.zoomScale;
    contentFrame.size.height *= self.scrollView.zoomScale;
    contentView.frame = contentFrame;
}

- (void) viewDidLayoutSubviews
{
    [self resetZoom];
    [self updateContentViewSize];
}

- (void) lowPreviewDidLoaded
{
    [self updateContentViewSize];
}

- (void) hiPreviewDidLoaded
{
    [self updateContentViewSize];
}


@end


