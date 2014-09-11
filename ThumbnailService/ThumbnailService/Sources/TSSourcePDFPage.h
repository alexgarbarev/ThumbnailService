//
//  TSSourcePDF.h
//  ThumbnailServiceDemo
//
//  Created by Sovelu on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSource.h"

typedef CGPDFPageRef(^TSSourcePDFPageLazyLoadingBlock)(NSString *name, NSInteger pageNumber);
typedef void(^TSSourcePDFPageLazyUnloadingBlock)(CGPDFPageRef page);

@interface TSSourcePDFPage : TSSource

@property (nonatomic, strong) UIColor *pageBackgroundColor;

/* Default: white */

- (id)initWithPdfPage:(CGPDFPageRef)page documentName:(NSString *)documentName;

- (id)initWithDocumentName:(NSString *)documentName pageNumber:(NSInteger)pageNumber
              loadingBlock:(TSSourcePDFPageLazyLoadingBlock)loadingBlock unloadingBlock:(TSSourcePDFPageLazyUnloadingBlock)unloadingBlock;


/* Override in subclasses */
- (UIImage *)thumbnailWithSize:(CGSize)size forPage:(CGPDFPageRef)page isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error;

@end
