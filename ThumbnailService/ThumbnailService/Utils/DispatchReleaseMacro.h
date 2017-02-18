//
// Created by Aleksey Garbarev on 11.09.14.
// Copyright (c) 2014 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TSDispatchRelease(q) (dispatch_release(q))

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
        #undef TSDispatchRelease
        #define TSDispatchRelease(q)
#endif
