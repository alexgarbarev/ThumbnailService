//
//  TSSourcePDF.m
//  ThumbnailServiceDemo
//
//  Created by Sovelu on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourcePdfPage.h"
#import "UIImageView+ImageFrame.h"

@implementation TSSourcePdfPage {
    CGPDFPageRef page;
    NSString *documentName;
}

- (id) initWithPdfPage:(CGPDFPageRef)_page documentName:(NSString *)_documentName
{
    self = [super init];
    if (self) {
        page = CGPDFPageRetain(_page);
        documentName = _documentName;
        self.pageBackgroundColor = [UIColor whiteColor];
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)dealloc
{
    CGPDFPageRelease(page);
}

- (NSString *) identifier
{
    return [NSString stringWithFormat:@"%@_%lu",documentName, CGPDFPageGetPageNumber(page)];
}

- (UIImage *) placeholder
{
    return [UIImage new];
}

- (UIImage *) thumbnailWithSize:(CGSize)size isCancelled:(BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    UIGraphicsBeginImageContext(size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect boundingRect = (CGRect){CGPointZero, size};
    
    CGRect pageFrame = [UIImageView imageFrameForImageSize:[self actualSize] boundingRect:boundingRect contentMode:self.contentMode];
    CGPoint pageScales = [UIImageView imageScalesForImageSize:[self actualSize] boundingRect:boundingRect contentMode:self.contentMode];
    
    if (self.pageBackgroundColor) {
        [self.pageBackgroundColor set];
        CGContextFillRect(context, pageFrame);
    }
    
    CGContextTranslateCTM(context, pageFrame.origin.x, pageFrame.size.height + pageFrame.origin.y);
    CGContextScaleCTM(context, pageScales.x, -pageScales.y);

    CGContextDrawPDFPage(context, page); 

    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

- (CGSize)actualSize
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

BOOL IsLandscapeAngel(NSInteger degrees)
{
    return degrees == 90 || degrees == 270;
}

@end
