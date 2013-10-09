//
//  TSRequest.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequest.h"
#import "TSRequest+Private.h"

@implementation TSRequest {
    BOOL needUpdateIdentifier;
    NSString *_cachedIdentifier;
}

- (NSString *) identifier
{
    if (needUpdateIdentifier || !_cachedIdentifier) {
        _cachedIdentifier = [[NSString alloc] initWithFormat:@"%@_%gx%g",[self.source identifier], self.size.width, self.size.height];
        needUpdateIdentifier = NO;
    }

    return _cachedIdentifier;
}

- (void) setSource:(TSSource *)source
{
    _source = source;
    needUpdateIdentifier = YES;
}

- (void) setSize:(CGSize)size
{
    _size = size;
    needUpdateIdentifier = YES;
}

- (void) setExpectedOperation:(TSOperation *)expectedOperation
{
    if (expectedOperation) {
        [_expectedOperation addExpectantRequest:self];
    } else {
        [_expectedOperation removeExpectantRequest:self];
    }
    _expectedOperation = expectedOperation;
}

- (void)setPriority:(NSOperationQueuePriority)priority
{
    _priority = priority;
    self.managedOperation.queuePriority = _priority;
}

- (void) cancel
{
    [self.managedOperation cancel];
    self.expectedOperation = nil;
    self.isCanceled = YES;
}


@end
