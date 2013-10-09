//
//  TSRequest.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSSource.h"

@interface TSRequest : NSObject

@property (nonatomic, strong) TSSource *source;
@property (nonatomic) CGSize size;

@property (nonatomic, copy) void(^placeholderBlock)(UIImage *placeholder);
@property (nonatomic, copy) void(^completionBlock)(UIImage *thumbnail);

@property (nonatomic) NSOperationQueuePriority priority;

- (void) cancel;

@end
