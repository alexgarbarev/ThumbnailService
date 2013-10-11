//
//  TSOperation.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRequest.h"

@interface TSOperation : NSOperation

@property (nonatomic, strong) UIImage *result;

@property (nonatomic, copy) dispatch_block_t cancellationBlock;

- (void) addExpectantRequest:(TSRequest *)request;
- (void) removeExpectantRequest:(TSRequest *)request;
- (NSArray *) expectantRequests;

@end
