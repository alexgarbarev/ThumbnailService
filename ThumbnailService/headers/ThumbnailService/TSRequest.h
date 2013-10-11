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

- (void) setPlaceholderCompletion:(TSRequestCompletion)placeholderBlock;
- (void) setThumbnailCompletion:(TSRequestCompletion)thumbnailBlock;

- (void) cancel;

- (void) waitUntilFinished;

/* You can shedule next request, which will performs just after current. 
   Useful when you want to show small thumb, then big
   Note: if you cancel request, it will cancel all next requests too */
- (void) setNextRequest:(TSRequest *)nextRequest;

@end
