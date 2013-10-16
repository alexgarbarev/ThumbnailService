//
//  TSRequest.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSSource.h"

typedef NS_ENUM(NSInteger, TSRequestThreadPriority)
{
    TSRequestThreadPriorityBackground,
    TSRequestThreadPriorityLow,
    TSRequestThreadPriorityNormal,
    TSRequestThreadPriorityHight
};

typedef NS_ENUM(NSInteger, TSRequestQueuePriority) {
	TSRequestQueuePriorityVeryLow = -8L,
	TSRequestQueuePriorityLow = -4L,
	TSRequestQueuePriorityNormal = 0,
	TSRequestQueuePriorityHigh = 4,
	TSRequestQueuePriorityVeryHigh = 8
};

typedef void(^TSRequestCompletion)(UIImage *result, NSError *error);

@interface TSRequest : NSObject

/* Thumbnail Source */
@property (nonatomic, strong) TSSource *source;

/* Priorities */
@property (nonatomic) TSRequestQueuePriority queuePriority;   /* Default: TSRequestQueuePriorityNormal */
@property (nonatomic) TSRequestThreadPriority threadPriority; /* Default: TSRequestThreadPriorityLow */

/* Thumbnail Size */
@property (nonatomic) BOOL shouldAdjustSizeToScreenScale;     /* Default: YES */
@property (nonatomic) CGSize size;

/* Caches options */
@property (nonatomic) BOOL shouldCacheInMemory; /* Default: YES */
@property (nonatomic) BOOL shouldCacheOnDisk;   /* Default: YES */

/* Completions */
@property (nonatomic) BOOL shouldCastCompletionsToMainThread; /* Default: YES */
- (void) setPlaceholderCompletion:(TSRequestCompletion)placeholderBlock;
- (void) setThumbnailCompletion:(TSRequestCompletion)thumbnailBlock;

/* Canceling request */
- (void) cancel;

/* Waiting for completions */
- (void) waitUntilFinished;
- (void) waitPlaceholder;


- (BOOL) isFinished;

@end
