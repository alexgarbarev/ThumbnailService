//
//  PreviewViewController.h
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewViewController : UIViewController

- (void) setSource:(id<UICollectionViewDelegate, UICollectionViewDataSource>)source;

@end
