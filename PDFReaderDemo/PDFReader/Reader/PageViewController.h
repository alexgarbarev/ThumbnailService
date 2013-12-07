//
//  PageViewController.h
//  PDFReader
//
//  Created by Sovelu on 26.11.13.
//  Copyright (c) 2013 Sovelu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ThumbnailService;

@interface PageViewController : UIViewController

@property (nonatomic, weak) ThumbnailService *thumbnailService;

@property (nonatomic) CGSize previewLowQualitylSize; /* Default: 150x150 */
@property (nonatomic) CGSize previewHighQualitySize; /* Default: 320x480 */

- (id) initWithPDFPage:(CGPDFPageRef)pdfPageRef documentName:(NSString *)documentName;

- (void) resetZoom;

@end
