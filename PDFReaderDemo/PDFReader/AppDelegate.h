//
//  AppDelegate.h
//  PDFReader
//
//  Created by Aleksey Garbarev on 26.11.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ThumbnailService/ThumbnailService.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) ThumbnailService *thumbnailService;

+ (AppDelegate *) sharedDelegate;

@end
