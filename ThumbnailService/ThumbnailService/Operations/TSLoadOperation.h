//
//  TSLoadOperation.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRequestedOperation.h"
#import "TSCacheManager.h"

@interface TSLoadOperation : TSRequestedOperation

- (id)initWithKey:(NSString *)key andCacheManager:(TSCacheManager *)cacheManager;

@end
