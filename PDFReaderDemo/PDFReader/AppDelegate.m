//
//  AppDelegate.m
//  PDFReader
//
//  Created by Aleksey Garbarev on 26.11.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "AppDelegate.h"
#import "MenuViewController.h"

@implementation AppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupWindow];
    [self setupThumbnailService];
    [self setupRootViewController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void) setupWindow
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
}

- (void) setupRootViewController
{
    MenuViewController *menu = [MenuViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:menu];
    navigationController.navigationBar.translucent = NO;
    self.window.rootViewController = navigationController;
}

- (void) setupThumbnailService
{
    self.thumbnailService = [[ThumbnailService alloc] init];
}

+ (AppDelegate *) sharedDelegate
{
    return (id)[[UIApplication sharedApplication] delegate];
}

@end
