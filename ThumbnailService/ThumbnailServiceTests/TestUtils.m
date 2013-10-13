//
//  TestUtils.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 13.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TestUtils.h"

void WaitAndCallInBackground(NSTimeInterval timeToWait, dispatch_block_t block)
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToWait * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block);
}
