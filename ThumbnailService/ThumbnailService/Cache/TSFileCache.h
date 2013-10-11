//
//  FileCache.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/* TSFileCache is threaded-safe */

@interface TSFileCache : NSCache

/* This class writes object to file instead of keep in memory. 
   So, all memory-related properties and methods from NSCache will not work */

- (void)setName:(NSString *)n;
- (NSString *)name;

- (BOOL) objectExistsForKey:(id)key;

- (id)objectForKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key; // 0 cost
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g; // cost is not used
- (void)removeObjectForKey:(id)key;

- (void)removeAllObjects;

@end