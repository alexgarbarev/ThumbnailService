//
//  TSSourcePDFPageLazy.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 07.12.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourcePDFPage.h"
#import "TSSourcePDFPageLazy.h"

@implementation TSSourcePDFPageLazy {
    NSString *documentName;
    size_t pageNumber;
    TSSourcePDFPageLazyLoadingBlock loadingBlock;
    TSSourcePDFPageLazyUnloadingBlock unloadingBlock;
}

- (id)initWithDocumentName:(NSString *)_documentName pageNumber:(size_t)_pageNumber
{
    self = [super init];
    if (self) {
        documentName = _documentName;
        pageNumber = _pageNumber;
        self.pageBackgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void) setPageLoadingBlock:(TSSourcePDFPageLazyLoadingBlock)block
{
    loadingBlock = [block copy];
}

- (void) setPageUnloadingBlock:(TSSourcePDFPageLazyUnloadingBlock)block
{
    unloadingBlock = [block copy];
}

- (NSString *) identifier
{
    return [NSString stringWithFormat:@"%@_%lu",documentName, pageNumber];
}

- (UIImage *) placeholder
{
    return [UIImage new];
}

- (UIImage *) thumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(loadingBlock);
    NSParameterAssert(unloadingBlock);
    
    CGPDFPageRef page = loadingBlock(documentName, pageNumber);
    
    TSSourcePDFPage *pageSource = [[TSSourcePDFPage alloc] initWithPdfPage:page documentName:documentName];
    pageSource.pageBackgroundColor = self.pageBackgroundColor;
    
    UIImage *thumb = [pageSource thumbnailWithSize:size isCancelled:isCancelled error:error];
    
    unloadingBlock(page);
    
    return thumb;
}

@end
