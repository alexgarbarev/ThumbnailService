//
//  ScrollViewController.h
//  PDFReader
//
//  Created by Aleksey Garbarev on 05.12.13.
//  Copyright (c) 2013 Sovelu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScrollingViewControllerDataSource;
@protocol ScrollingViewControllerDelegate;

@interface ScrollViewController : UIViewController

@property (nonatomic) NSInteger currentIndex;
@property (nonatomic) NSUInteger numberOfPagesInMemory; /* Default: 3 (previous, current, next)*/

@property (nonatomic, weak) id<ScrollingViewControllerDataSource>dataSource;
@property (nonatomic, weak) id<ScrollingViewControllerDelegate>delegate;

@end


@protocol ScrollingViewControllerDataSource <NSObject>

- (NSInteger) numberOfViewControllersForScrollingController:(ScrollViewController *)scrollingController;

- (UIViewController *) scrollingController:(ScrollViewController *)controller viewControllerAtIndex:(NSInteger)index;

@end

@protocol ScrollingViewControllerDelegate <NSObject>

@optional
- (void) scrollingController:(ScrollViewController *)controller willChangeCurrentIndexTo:(NSInteger)index;
- (void) scrollingController:(ScrollViewController *)controller didChangeCurrentIndexTo:(NSInteger)index;

- (void) scrollingController:(ScrollViewController *)controller didChangeVisiblePagesIndecies:(NSIndexSet *)visibleIndecies;
@end
