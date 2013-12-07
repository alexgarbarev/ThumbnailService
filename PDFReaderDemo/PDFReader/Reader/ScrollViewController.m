//
//  ScrollViewController.m
//  PDFReader
//
//  Created by Aleksey Garbarev on 05.12.13.
//  Copyright (c) 2013 Sovelu. All rights reserved.
//

#import "ScrollViewController.h"

@interface ScrollViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *view;

@end

@implementation ScrollViewController {
    NSMutableIndexSet *visibleIndecies;
    NSMutableDictionary *visiblePages;
    
    NSInteger lastLeftIndex;
    NSInteger lastRightIndex;
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _currentIndex = -1;
        self.numberOfPagesInMemory = 3;
        visiblePages = [[NSMutableDictionary alloc] initWithCapacity:self.numberOfPagesInMemory];
    }
    return self;
}

- (void) loadView
{
    self.view = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.delegate = self;
    self.view.pagingEnabled = YES;
}

- (void) setNumberOfPagesInMemory:(NSUInteger)numberOfPagesInMemory
{
    if (numberOfPagesInMemory % 2 == 0) {
        numberOfPagesInMemory -= 1;
    }
    numberOfPagesInMemory = MAX(1, numberOfPagesInMemory);
    
    _numberOfPagesInMemory = numberOfPagesInMemory;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self setupContentSize];
    
    visibleIndecies = [NSMutableIndexSet new];
    
    self.currentIndex = 0;
}

- (void) viewDidLayoutSubviews
{
    [self setupContentSize];
    [self layoutViewControllers];
}

- (void) layoutViewControllers
{
    [[visibleIndecies copy] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        UIViewController *controller = [self visibleViewControllerAtIndex:idx];
        if (controller) {
            CGPoint origin = CGPointMake(idx * [self pageWidth], 0);
            controller.view.frame = (CGRect){origin, self.view.bounds.size};
        }
    }];
}

- (void) setCurrentIndex:(NSInteger)currentIndex
{
    _currentIndex = currentIndex;
    
    NSInteger location = MAX((NSInteger)(_currentIndex - _numberOfPagesInMemory/2), 0);
    
    [self willChangeCurrentIndexTo:_currentIndex];
    
    NSIndexSet *indecies = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(location, _numberOfPagesInMemory)];
    [self setViewControllersAtIndecies:indecies];
    
    [self didChangeCurrentIndexTo:_currentIndex];
}

- (void) setupContentSize
{
    NSInteger count = [self numberOfViewControllers];
    self.view.contentSize = CGSizeMake(count * [self pageWidth], self.view.frame.size.height);
}

- (void) scrollToViewControllerAtIndex:(NSInteger)index
{
    self.view.contentOffset = CGPointMake(index * [self pageWidth], 0);
}

- (void) setViewControllersAtIndecies:(NSIndexSet *)indecies
{
    NSIndexSet *indeciesToRemove = [visibleIndecies indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return ![indecies containsIndex:idx];
    }];
    
    NSIndexSet *indexToAdd = [indecies indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return ![visibleIndecies containsIndex:idx];
    }];
    
    [self addViewControllersAtIndexes:indexToAdd];
    [self removeViewControllersAtIndexes:indeciesToRemove];
    
    visibleIndecies = [indecies mutableCopy];
}

- (void) addViewControllersAtIndexes:(NSIndexSet *)indexes
{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        UIViewController *controller = [self viewControllerAtIndex:idx];
        [self addViewController:controller atIndex:idx];
    }];
}

- (void) removeViewControllersAtIndexes:(NSIndexSet *)indexes
{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        UIViewController *controller = [self visibleViewControllerAtIndex:idx];
        [self removeViewController:controller atIndex:idx];
    }];
}

- (CGFloat) pageWidth
{
    return self.view.bounds.size.width;
}

- (void) addViewController:(UIViewController *)controller atIndex:(NSInteger)index
{
    if (!controller) {
        return;
    }
    
    [controller willMoveToParentViewController:self];
    
    [self addChildViewController:controller];

    CGPoint origin = CGPointMake(index * [self pageWidth], 0);
    controller.view.frame = (CGRect){origin, self.view.bounds.size};
    [self.view addSubview:controller.view];
    
    [controller didMoveToParentViewController:self];
    
    visiblePages[@(index)] = controller;
}

- (void) removeViewController:(UIViewController *)controller atIndex:(NSInteger)index
{
    if (!controller) {
        return;
    }
    
    [controller willMoveToParentViewController:nil];
    [controller removeFromParentViewController];
    
    controller.view.frame = (CGRect){CGPointZero, self.view.bounds.size};
    [controller.view removeFromSuperview];
    
    [controller didMoveToParentViewController:nil];
    
    [visiblePages removeObjectForKey:@(index)];
}

#pragma mark -

- (NSInteger) numberOfViewControllers
{
    return [self.dataSource numberOfViewControllersForScrollingController:self];
}

- (UIViewController *) visibleViewControllerAtIndex:(NSInteger)index
{
    return visiblePages[@(index)];
}

- (UIViewController *) viewControllerAtIndex:(NSInteger)index
{
    UIViewController *controller = nil;
    
    if (index >= 0 && index <= [self numberOfViewControllers] - 1) {
        controller = [self.dataSource scrollingController:self viewControllerAtIndex:index];
    }
    
    return controller;
}

- (void) willChangeCurrentIndexTo:(NSInteger)newIndex
{
    if ([self.delegate respondsToSelector:@selector(scrollingController:willChangeCurrentIndexTo:)]) {
        [self.delegate scrollingController:self willChangeCurrentIndexTo:newIndex];
    }
}

- (void) didChangeCurrentIndexTo:(NSInteger)newIndex
{
    if ([self.delegate respondsToSelector:@selector(scrollingController:didChangeCurrentIndexTo:)]) {
        [self.delegate scrollingController:self didChangeCurrentIndexTo:newIndex];
    }
}

- (void) updateVisiblePages
{
    NSInteger leftIndex = self.view.contentOffset.x / (int)[self pageWidth];
    NSInteger rightIndex = (self.view.contentOffset.x + [self pageWidth] - 1) / (int)[self pageWidth];
    if (lastLeftIndex != leftIndex || lastRightIndex != rightIndex) {
        lastLeftIndex = leftIndex;
        lastRightIndex = rightIndex;
        
        if ([self.delegate respondsToSelector:@selector(scrollingController:didChangeVisiblePagesIndecies:)]) {
            NSIndexSet *set  = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(leftIndex, rightIndex - leftIndex + 1)];
            [self.delegate scrollingController:self didChangeVisiblePagesIndecies:set];
        }
    }
}

#pragma mark - ScrollView delegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger index = (scrollView.contentOffset.x + [self pageWidth]*0.5f) / (int)[self pageWidth];
    if (index != _currentIndex) {
        self.currentIndex = index;
    }
    [self updateVisiblePages];
}

@end
