//
//  PreviewViewController.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "PreviewViewController.h"

@interface PreviewViewController ()
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation PreviewViewController {
    id<UICollectionViewDelegate, UICollectionViewDataSource> source;
}

- (void)viewDidLoad
{
    self.collectionView.delegate = source;
    self.collectionView.dataSource = source;
    
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    [super viewDidLoad];
}

- (void) setSource:(id<UICollectionViewDelegate, UICollectionViewDataSource>)_source
{
    source = _source;
}

- (void) dealloc
{
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    source = nil;
}

@end
