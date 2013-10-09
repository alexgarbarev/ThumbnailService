//
//  TSLoadOperation.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSOperation.h"
#import "TSFileCache.h"

@interface TSLoadOperation : TSOperation

- (id) initWithKey:(NSString *)key andFileCache:(TSFileCache *)fileCache;

@end
