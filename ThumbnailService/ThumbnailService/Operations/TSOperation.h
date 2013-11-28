//
//  TSOperation.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRequest.h"

typedef NS_ENUM(NSInteger, TSOperationDispatchQueuePriority)
{
    TSOperationDispatchQueuePriorityBackground,
    TSOperationDispatchQueuePriorityLow,
    TSOperationDispatchQueuePriorityNormal,
    TSOperationDispatchQueuePriorityHight
};

@class TSOperation;
typedef void(^TSOperationCompletion)(TSOperation *operation);

@interface TSOperation : NSOperation

@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSError *error;

/* Completion block is unavailable, since addCompletionBlock method available */
- (void (^)(void))completionBlock NS_AVAILABLE(10_6, 4_0) UNAVAILABLE_ATTRIBUTE;
- (void)setCompletionBlock:(void (^)(void))block NS_AVAILABLE(10_6, 4_0) UNAVAILABLE_ATTRIBUTE;

/* threadPriority is unavailable, since we using dispatch_queue inside and you can control priority by dispatchQueuePrioriy */
- (double) threadPriority NS_AVAILABLE(10_6, 4_0) UNAVAILABLE_ATTRIBUTE;
- (void) setThreadPriority:(double)p NS_AVAILABLE(10_6, 4_0) UNAVAILABLE_ATTRIBUTE;

/* Callbacks */
- (void) addCompleteBlock:(TSOperationCompletion)completionBlock;
- (void) addCancelBlock:(TSOperationCompletion)cancelBlock;

/* Thread priority */
- (void) setDispatchQueuePriority:(TSOperationDispatchQueuePriority)priority;
- (TSOperationDispatchQueuePriority) dispatchQueuePriority;

@end
