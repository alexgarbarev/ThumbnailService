//
//  TSGenerateOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSGenerateOperation.h"

@interface TSGenerateOperation()

@property (nonatomic, getter = isFinished)  BOOL finished;
@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isStarted)   BOOL started;
@end

@implementation TSGenerateOperation {
    TSSource *source;
    CGSize size;
    BOOL isCancelled;
}

- (id) initWithSource:(TSSource *)_source size:(CGSize)_size
{
    self = [super init];
    if (self) {
        source = _source;
        size = _size;
        isCancelled = NO;
        
    }
    return self;
}

- (void)start
{
    self.started = YES;
    if (![self isCancelled]) {
        self.executing = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [self main];
            self.executing = NO;
            self.finished = YES;
        });
    } else {
        self.finished = YES;
    }
}

- (BOOL) isConcurrent
{
    return YES;
}

- (void) main
{
    @autoreleasepool {
        if (![self isCancelled]) {
            NSError *error = nil;
            self.result = [source thumbnailWithSize:size isCancelled:&isCancelled error:&error];
            self.error = error;
        }
    }
}

- (void)setExecuting:(BOOL)isExecuting
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)isFinished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}


- (BOOL) isCancelled
{
    return isCancelled;
}

- (void) cancel
{
    if (!self.finished) {
        
        isCancelled = YES;
        
        if (self.started) {
            self.finished = YES;
        }
        
        self.result = nil;
        self.error = [NSError errorWithDomain:@"TSGenerateOperation" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Operation did cancelled"}];
        
        [super cancel];
    }
}

@end
