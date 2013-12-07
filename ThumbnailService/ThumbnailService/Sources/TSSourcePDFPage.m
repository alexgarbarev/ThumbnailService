//
//  TSSourcePDF.m
//  ThumbnailServiceDemo
//
//  Created by Sovelu on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourcePDFPage.h"
#import "UIImageView+ImageFrame.h"

@implementation TSSourcePDFPage {
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
    }
    return self;
}

- (void) dealloc
{
    CGPDFPageRelease(page);
}

- (NSString *) identifier
{
    return [NSString stringWithFormat:@"%@_%lu",documentName, CGPDFPageGetPageNumber(page)];
}

- (UIImage *) placeholder
{
    static UIImage *placeholder = nil;
    if (!placeholder) {
        CGRect boundingRect = (CGRect){CGPointZero, CGSizeMake(140, 140)};
        CGRect placeholderFrame = [UIImageView imageFrameForImageSize:[self actualSize] boundingRect:boundingRect contentMode:UIViewContentModeScaleAspectFit];
        placeholderFrame.origin = CGPointZero;
        
        UIGraphicsBeginImageContextWithOptions(placeholderFrame.size, NO, 1.0);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        [[UIColor whiteColor] set];
        CGContextFillRect(context, (CGRect){CGPointZero, placeholderFrame.size});
        
        placeholder = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return placeholder;
}

- (UIImage *) thumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    CGRect boundingRect = (CGRect){CGPointZero, size};
    
    CGRect pageFrame = [UIImageView imageFrameForImageSize:[self actualSize] boundingRect:boundingRect contentMode:UIViewContentModeScaleAspectFit];
    CGPoint pageScales = [UIImageView imageScalesForImageSize:[self actualSize] boundingRect:boundingRect contentMode:UIViewContentModeScaleAspectFit];
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

- (CGSize) actualSize
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

@end
