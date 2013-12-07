//
//  TSSourcePDFPageLazy.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 07.12.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSource.h"

typedef CGPDFPageRef(^TSSourcePDFPageLazyLoadingBlock)(NSString *name, NSInteger pageNumber);
typedef void(^TSSourcePDFPageLazyUnloadingBlock)(CGPDFPageRef page);

@interface TSSourcePDFPageLazy : TSSource

@property (nonatomic, strong) UIColor *pageBackgroundColor; /* Default: white */

- (id) initWithDocumentName:(NSString *)documentName pageNumber:(size_t)pageNumber;

- (void) setPageLoadingBlock:(TSSourcePDFPageLazyLoadingBlock)block;
- (void) setPageUnloadingBlock:(TSSourcePDFPageLazyUnloadingBlock)block;
@end
