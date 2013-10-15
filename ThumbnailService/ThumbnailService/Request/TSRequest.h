//
//  TSRequest.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSSource.h"

typedef void(^TSRequestCompletion)(UIImage *result, NSError *error);

@interface TSRequest : NSObject

@property (nonatomic, strong) TSSource *source;
@property (nonatomic) CGSize size;
@property (nonatomic) NSOperationQueuePriority priority;

@property (nonatomic) BOOL shouldAdjustSizeToScreenScale;     /* Default: YES */
@property (nonatomic) BOOL shouldCastCompletionsToMainThread; /* Default: YES */

- (void) setPlaceholderCompletion:(TSRequestCompletion)placeholderBlock;
- (void) setThumbnailCompletion:(TSRequestCompletion)thumbnailBlock;

- (void) cancel;
- (void) cancelAndWait:(BOOL)wait;

- (void) waitUntilFinished;
- (void) waitPlaceholder;


- (BOOL) isFinished;

@end
