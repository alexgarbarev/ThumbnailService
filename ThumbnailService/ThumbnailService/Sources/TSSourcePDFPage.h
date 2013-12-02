//
//  TSSourcePDF.h
//  ThumbnailServiceDemo
//
//  Created by Sovelu on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSource.h"

@interface TSSourcePDFPage : TSSource

@property (nonatomic, strong) UIColor *pageBackgroundColor; /* Default: white */

- (id) initWithPdfPage:(CGPDFPageRef)page documentName:(NSString *)documentName;

@end
