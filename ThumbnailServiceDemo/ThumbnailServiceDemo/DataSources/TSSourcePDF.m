//
//  TSSourcePDF.m
//  ThumbnailServiceDemo
//
//  Created by Sovelu on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourcePDF.h"

@implementation TSSourcePDF {
    CGPDFPageRef page;
}

- (id) initWithPdfPage:(CGPDFPageRef)_page
{
    self = [super init];
    if (self) {
        page = CGPDFPageRetain(_page);
    }
    return self;
}

- (void)dealloc
{
    CGPDFPageRelease(page);
}

- (NSString *) guidFromPDFDocumentRef:(CGPDFDocumentRef) documentRef{
    
    NSMutableString * guid = [[NSMutableString alloc] init];
    
    CGPDFArrayRef idArray = CGPDFDocumentGetID(documentRef);
    
    CGPDFStringRef idString;
    
    for (int i = 0; i < CGPDFArrayGetCount(idArray); i++){
        if (CGPDFArrayGetString(idArray, 0, &idString)) {
            size_t j = 0, k = 0, length = CGPDFStringGetLength(idString);
            const unsigned char *inputBuffer = CGPDFStringGetBytePtr(idString);
            unsigned char outputBuffer[length * 2]; // length should be 16 so no need to malloc
            static unsigned char hexEncodeTable[17] = "0123456789abcdef";
            
            for (j = 0; j < length; j++) {
                outputBuffer[k++] = hexEncodeTable[(inputBuffer[j] & 0xF0) >> 4];
                outputBuffer[k++] = hexEncodeTable[(inputBuffer[j] & 0x0F)];
            }
            [guid appendString:[[NSString alloc] initWithBytes:outputBuffer length:k encoding:NSASCIIStringEncoding]];
        }
    }
    return guid;
}

- (NSString *) guidFromPDFPageRef:(CGPDFPageRef) pageRef{
    return [self guidFromPDFDocumentRef:CGPDFPageGetDocument(pageRef)];
}

- (NSString *) identifier
{
//    NSString *identifier = [self guidFromPDFPageRef:page];
//    NSLog(@"id: %@",identifier);
    return [NSString stringWithFormat:@"%lu",CGPDFPageGetPageNumber(page)];
}

- (UIImage *) placeholder
{
    return [UIImage new];
}

- (UIImage *) thumbnailWithSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rect = (CGRect){CGPointZero, size};
    
    CGSize actualSize = self.actualSize;
    /* If requested size more than actual size */
    if (rect.size.width > actualSize.width || rect.size.height > actualSize.height){
        
        CGFloat scalex = rect.size.width / actualSize.width;
        CGFloat scaley = rect.size.height / actualSize.height;
        CGFloat scale = MAX(scalex, scaley);
        
        rect.size = self.actualSize;
        
        CGContextScaleCTM(context,scale,scale);
    }

    CGContextConcatCTM(context, CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, rect, 0, true));
    CGContextDrawPDFPage(context, page); //Render the PDF page into the context

    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

- (CGSize)actualSize
{
    CGRect cropBoxRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    CGRect effectiveRect = CGRectIntersection(cropBoxRect, mediaBoxRect);
    
    NSInteger pageRotate = CGPDFPageGetRotationAngle(page); // Angle
    
    CGFloat page_w = 0.0f; CGFloat page_h = 0.0f; // Rotated page size
    
    switch (pageRotate) // Page rotation (in degrees)
    {
        default: // Default case
        case 0: case 180: // 0 and 180 degrees
        {
            page_w = effectiveRect.size.width;
            page_h = effectiveRect.size.height;
            break;
        }
            
        case 90: case 270: // 90 and 270 degrees
        {
            page_h = effectiveRect.size.width;
            page_w = effectiveRect.size.height;
            break;
        }
    }
    return CGSizeMake(page_w, page_h);
}

@end
