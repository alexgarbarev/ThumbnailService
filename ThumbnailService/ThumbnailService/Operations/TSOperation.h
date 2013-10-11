//
//  TSOperation.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRequest.h"

@class TSOperation;
typedef void(^TSOperationCompletion)(TSOperation *operation);

@interface TSOperation : NSOperation

@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSError *error;

/* Relations with request */
- (void) addRequest:(TSRequest *)request;
- (void) removeRequest:(TSRequest *)request;
- (NSSet *) requests;

- (void) updatePriority;

/* Completion block is unavailable, since addCompletionBlock method available */
- (void (^)(void))completionBlock NS_AVAILABLE(10_6, 4_0) UNAVAILABLE_ATTRIBUTE;
- (void)setCompletionBlock:(void (^)(void))block NS_AVAILABLE(10_6, 4_0) UNAVAILABLE_ATTRIBUTE;

/* Callbacks */
- (void) addCompleteBlock:(TSOperationCompletion)completionBlock;
- (void) addCancelBlock:(TSOperationCompletion)cancelBlock;

@end
