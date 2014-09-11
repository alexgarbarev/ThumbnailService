//
//  TSGenerateOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSGenerateOperation.h"

@interface TSGenerateOperation ()

@end

@implementation TSGenerateOperation
{
    TSSource *source;
    CGSize size;
    BOOL isCancelled;
}

- (id)initWithSource:(TSSource *)_source size:(CGSize)_size
{
    self = [super init];
    if (self) {
        source = _source;
        size = _size;
        isCancelled = NO;

    }
    return self;
}

- (void)main
{
    @autoreleasepool {
        if (![self isCancelled]) {
            NSError *error = nil;
            self.result = [source thumbnailWithSize:size isCancelled:&isCancelled error:&error];
            self.error = error;
        }
    }
}

- (BOOL)isCancelled
{
    return isCancelled;
}

- (void)cancel
{
    if (![self isFinished]) {

        isCancelled = YES;

        self.result = nil;
        self.error = [NSError errorWithDomain:@"TSGenerateOperation" code:1 userInfo:@{NSLocalizedDescriptionKey : @"Operation did cancelled"}];

        [super cancel];
    }
}

@end
