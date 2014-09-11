//
//  TSSourcePDF.m
//  ThumbnailServiceDemo
//
//  Created by Sovelu on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourcePDFPage.h"
#import "UIImageView+ImageFrame.h"

static BOOL IsLandscapeAngel(NSInteger degrees);

@implementation TSSourcePDFPage
{
    size_t pageNumber;
    NSString *documentName;

    /* Lazy loading */
    TSSourcePDFPageLazyLoadingBlock loadingBlock;
    TSSourcePDFPageLazyUnloadingBlock unloadingBlock;

    /* Not Lazy loading */
    CGPDFPageRef thePage;
}

- (id)initWithPdfPage:(CGPDFPageRef)_page documentName:(NSString *)_documentName
{
    self = [super init];
    if (self) {
        NSParameterAssert(_documentName);
        NSParameterAssert(_page);
        thePage = CGPDFPageRetain(_page);
        pageNumber = CGPDFPageGetPageNumber(_page);
        documentName = _documentName;
        self.pageBackgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (id)initWithDocumentName:(NSString *)_documentName pageNumber:(NSInteger)_pageNumber loadingBlock:(TSSourcePDFPageLazyLoadingBlock)_loadingBlock unloadingBlock:(TSSourcePDFPageLazyUnloadingBlock)_unloadingBlock
{
    self = [super init];
    if (self) {
        NSParameterAssert(_documentName);
        NSParameterAssert(_loadingBlock);
        NSParameterAssert(_unloadingBlock);
        documentName = _documentName;
        pageNumber = (size_t)_pageNumber;
        loadingBlock = [_loadingBlock copy];
        unloadingBlock = [_unloadingBlock copy];
        self.pageBackgroundColor = [UIColor whiteColor];
        thePage = NULL;
    }
    return self;
}

- (void)dealloc
{
    if (![self isLazyLoading]) {
        CGPDFPageRelease(thePage);
    }
}

- (NSString *)identifier
{
    return [NSString stringWithFormat:@"%@_%lu", documentName, pageNumber];
}

- (UIImage *)placeholder
{
    static UIImage *placeholder = nil;
    if (!placeholder) {
        CGPDFPageRef page = [self loadPage];
        CGRect boundingRect = (CGRect){CGPointZero, CGSizeMake(140, 140)};
        CGRect placeholderFrame = [UIImageView imageFrameForImageSize:[self actualSizeForPage:page] boundingRect:boundingRect contentMode:UIViewContentModeScaleAspectFit];
        placeholderFrame.origin = CGPointZero;

        UIGraphicsBeginImageContextWithOptions(placeholderFrame.size, NO, 1.0);

        CGContextRef context = UIGraphicsGetCurrentContext();

        [[UIColor whiteColor] set];
        CGContextFillRect(context, (CGRect){CGPointZero, placeholderFrame.size});

        placeholder = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self unloadPage:page];
    }

    return placeholder;
}

- (UIImage *)thumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    CGPDFPageRef page = [self loadPage];
    UIImage *thumbnail = [self thumbnailWithSize:size forPage:page isCancelled:isCancelled error:error];
    [self unloadPage:page];
    return thumbnail;
}

- (UIImage *)thumbnailWithSize:(CGSize)size forPage:(CGPDFPageRef)page isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)__unused error
{
    CGRect boundingRect = (CGRect){CGPointZero, size};

    CGRect pageFrame = [UIImageView imageFrameForImageSize:[self actualSizeForPage:page] boundingRect:boundingRect contentMode:UIViewContentModeScaleAspectFit];
    CGPoint pageScales = [UIImageView imageScalesForImageSize:[self actualSizeForPage:page] boundingRect:boundingRect contentMode:UIViewContentModeScaleAspectFit];
    pageFrame.origin = CGPointZero;

    UIGraphicsBeginImageContext(pageFrame.size);

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetRenderingIntent(context, kCGRenderingIntentDefault);

    if (self.pageBackgroundColor) {
        [self.pageBackgroundColor set];
        CGContextFillRect(context, pageFrame);
    }

    CGContextTranslateCTM(context, pageFrame.origin.x, pageFrame.size.height + pageFrame.origin.y);
    CGContextScaleCTM(context, pageScales.x, -pageScales.y);

    if (*isCancelled) {
        UIGraphicsEndImageContext();
        return nil;
    }


    CGContextDrawPDFPage(context, page);


    CGImageRef imageRef = CGBitmapContextCreateImage(context);

    UIGraphicsEndImageContext();

    UIImage *result = [UIImage imageWithCGImage:imageRef];

    CGImageRelease(imageRef);

    return result;
}

- (CGSize)actualSizeForPage:(CGPDFPageRef)page
{
    CGRect cropBoxRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    CGRect effectiveRect = CGRectIntersection(cropBoxRect, mediaBoxRect);

    NSInteger pageRotationAngle = CGPDFPageGetRotationAngle(page);

    CGSize actualSize;

    if (IsLandscapeAngel(pageRotationAngle)) {
        actualSize.width = effectiveRect.size.height;
        actualSize.height = effectiveRect.size.width;
    } else {
        actualSize.width = effectiveRect.size.width;
        actualSize.height = effectiveRect.size.height;
    }
    return actualSize;
}

static BOOL IsLandscapeAngel(NSInteger degrees)
{
    return degrees == 90 || degrees == 270;
}

#pragma mark - Page Lazy loading 

- (BOOL)isLazyLoading
{
    return loadingBlock && unloadingBlock && thePage == NULL;
}

- (CGPDFPageRef)loadPage
{
    CGPDFPageRef page = NULL;
    if ([self isLazyLoading]) {
        page = loadingBlock(documentName, pageNumber);
    } else {
        page = thePage;
    }
    return page;
}

- (void)unloadPage:(CGPDFPageRef)page
{
    if ([self isLazyLoading]) {
        unloadingBlock(page);
    }
}

@end
