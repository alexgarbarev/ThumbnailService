//
//  TSGenerateOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSGenerateOperation.h"

@implementation TSGenerateOperation {
    TSSource *source;
    CGSize size;
}

- (id) initWithSource:(TSSource *)_source size:(CGSize)_size
{
    self = [super init];
    if (self) {
        source = _source;
        size = _size;
    }
    return self;
}

- (void) main
{
    @autoreleasepool {
        if (![self isCancelled]) {
            self.result = [source thumbnailWithSize:size];
        }
        if ([self isCancelled]) {
            self.result = nil;
        }
    }
}

- (void) cancel
{
    self.result = nil;
    [super cancel];
}

@end
