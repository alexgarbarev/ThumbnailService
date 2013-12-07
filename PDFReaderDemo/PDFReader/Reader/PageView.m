//
//  PageView.m
//  PDFReader
//
//  Created by Sovelu on 26.11.13.
//  Copyright (c) 2013 Sovelu. All rights reserved.
//

#import "PageView.h"
#import "UIImageView+ImageFrame.h"
#import <QuartzCore/QuartzCore.h>

@interface PageView ()
@property (nonatomic, strong) UIColor *backgroundContentColor;
@end

@implementation PageView {
    CGPDFPageRef page;
}

- (id) initPDFPage:(CGPDFPageRef)_page
{
    self = [super init];
    if (self) {
        page = _page;
        self.backgroundContentColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor blackColor];
        self.contentMode = UIViewContentModeRedraw;
        CATiledLayer *layer = (CATiledLayer*)self.layer;
        layer.levelsOfDetail = 4;
        layer.levelsOfDetailBias = 3;
        layer.tileSize = CGSizeMake(1024, 1024);
        self.contentMode = UIViewContentModeRedraw;
        
    }
    return self;
}

+ (Class) layerClass
{
    return [CATiledLayer class];
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect pageFrame = [UIImageView imageFrameForImageSize:[self actualSize] boundingRect:self.bounds contentMode:UIViewContentModeScaleAspectFit];
    CGPoint pageScales = [UIImageView imageScalesForImageSize:[self actualSize] boundingRect:self.bounds contentMode:UIViewContentModeScaleAspectFit];
    
    if (self.backgroundContentColor) {
        [self.backgroundContentColor set];
        CGContextFillRect(context, pageFrame);
    }
    
    CGContextTranslateCTM(context, pageFrame.origin.x, pageFrame.size.height + pageFrame.origin.y);
    CGContextScaleCTM(context, pageScales.x, -pageScales.y);
    
    CGContextDrawPDFPage(context, page);
}

- (CGSize) actualSize
{
    CGRect cropBoxRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    CGRect effectiveRect = CGRectIntersection(cropBoxRect, mediaBoxRect);
    
    NSInteger pageRotationAngle = CGPDFPageGetRotationAngle(page);
    
    CGSize actualSize;
    
    BOOL isLandscape = pageRotationAngle == 90 || pageRotationAngle == 270;
    if (isLandscape) {
        actualSize.width = effectiveRect.size.height;
        actualSize.height = effectiveRect.size.width;
    } else {
        actualSize.width = effectiveRect.size.width;
        actualSize.height = effectiveRect.size.height;
    }
    return actualSize;
}

@end
