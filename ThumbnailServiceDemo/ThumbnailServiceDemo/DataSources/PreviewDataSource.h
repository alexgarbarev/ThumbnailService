//
//  PreviewDataSource.h
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 14.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PreviewDataSource <NSObject>

- (void) setShouldPrecache:(BOOL)_shouldPrecache;
- (void) setUseMemoryCache:(BOOL)_useMemoryCache;
- (void) setUseFileCache:(BOOL)_useFileCache;

@end
