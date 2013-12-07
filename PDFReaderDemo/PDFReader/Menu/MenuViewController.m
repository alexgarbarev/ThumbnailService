//
//  MenuViewController.m
//  PDFReader
//
//  Created by Sovelu on 26.11.13.
//  Copyright (c) 2013 Sovelu. All rights reserved.
//

#import "MenuViewController.h"
#import "ReaderViewController.h"
#import "AppDelegate.h"

@interface MenuViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray *allPaths;
@end

@implementation MenuViewController {
    NSMutableDictionary *requestsForCells;
}

- (NSArray *) arrayOfAllPdfs
{
    return [[NSBundle mainBundle] pathsForResourcesOfType:@"pdf" inDirectory:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.allPaths = [self arrayOfAllPdfs];
        requestsForCells = [[NSMutableDictionary alloc] initWithCapacity:[self.allPaths count]];
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.allPaths count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSString *path = self.allPaths[indexPath.row];
    cell.textLabel.text = [path lastPathComponent];
    cell.tag = indexPath.row;
    
    [self requestThubmnailForCell:cell withPdfPath:path];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *path = self.allPaths[indexPath.row];
    ReaderViewController *readerViewController = [[ReaderViewController alloc] initWithPdfPath:path];
    [self.navigationController pushViewController:readerViewController animated:YES];
}

- (void) requestThubmnailForCell:(UITableViewCell *)cell withPdfPath:(NSString *)path
{
    TSSourcePDFPageLazy *source = [[TSSourcePDFPageLazy alloc] initWithDocumentName:[path lastPathComponent] pageNumber:1];
    
    [source setPageLoadingBlock:^CGPDFPageRef(NSString *name, NSInteger pageNumber) {
        CGPDFDocumentRef doc = CGPDFDocumentCreateWithURL((__bridge CFURLRef)[[NSURL alloc] initFileURLWithPath:path]);
        CGPDFPageRef page = CGPDFDocumentGetPage(doc, pageNumber);
        return page;
    }];
    
    [source setPageUnloadingBlock:^(CGPDFPageRef page) {
        CGPDFDocumentRef document = CGPDFPageGetDocument(page);
        CGPDFDocumentRelease(document);
    }];

    NSUInteger requestTag = cell.tag;
    
    TSRequest *request = [TSRequest new];
    request.source = source;
    request.size = CGSizeMake(45, 45);
    request.shouldCastCompletionsToMainThread = YES;
    [request setThumbnailCompletion:^(UIImage *result, NSError *error) {
        if (cell.tag == requestTag) {
            cell.imageView.image = result;
            [cell setNeedsDisplay];
            [cell setNeedsLayout];
        }
    }];
    
    ThumbnailService *service = [AppDelegate sharedDelegate].thumbnailService;
    if ([service hasDiskCacheForRequest:request]) {
        [service executeRequest:request];
    } else {
        [service enqueueRequest:request];
    }
}

@end
