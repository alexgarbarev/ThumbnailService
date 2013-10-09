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

@interface MenuViewController ()

@end

@implementation MenuViewController {
    Class selectedSourceClass;
}

- (void)viewDidLoad
{
    selectedSourceClass = [AssetsCollectionDataSource class];
    [super viewDidLoad];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PreviewViewController *previewVC = segue.destinationViewController;
    id source = [selectedSourceClass new];
    [previewVC setSource:source];
}

@end
