//
//  ViewController.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "MenuViewController.h"
#import "AssetsCollectionDataSource.h"
#import "PreviewViewController.h"
#import "PDFCollectionDataSource.h"
#import "ImagesCollectionDataSource.h"
#import "VideosCollectionDataSource.h"

#import <ThumbnailService/ThumbnailService.h>
#import "PreviewDataSource.h"

@interface MenuViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *menuSegmentedControl;

@end

@implementation MenuViewController 

- (Class) classForSelectedIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
            return [AssetsCollectionDataSource class];
        case 1:
            return [PDFCollectionDataSource class];
        case 2:
            return [ImagesCollectionDataSource class];
        case 3:
            return [VideosCollectionDataSource class];
    }
    return nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    Class selectedSourceClass = [self classForSelectedIndex:[self.menuSegmentedControl selectedSegmentIndex]];
    PreviewViewController *previewVC = segue.destinationViewController;
    id<PreviewDataSource> source = [selectedSourceClass new];
    [source setUseFileCache:YES];
    [source setUseMemoryCache:YES];
    [source setShouldPrecache:YES];
    [previewVC setSource:(id)source];
}

- (IBAction)clearFileCache:(id)sender
{
    ThumbnailService *service = [[ThumbnailService alloc] init];
    [service clearFileCache];
}

@end
