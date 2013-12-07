//
//  PageView.h
//  PDFReader
//
//  Created by Sovelu on 26.11.13.
//  Copyright (c) 2013 Sovelu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PageView : UIView

- (id) initPDFPage:(CGPDFPageRef)page;

@end
