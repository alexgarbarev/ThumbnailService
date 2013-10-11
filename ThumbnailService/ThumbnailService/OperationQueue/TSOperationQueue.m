//
//  TSOperationQueue.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 11.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperationQueue.h"

@implementation TSOperationQueue {
    NSMutableDictionary *dictionary;
    
    NSMutableSet *cancelBlocks;
    NSMutableSet *completeBlock;
}

- (id)init
{
    self = [super init];
    if (self) {
        dictionary = [NSMutableDictionary new];
    }
    return self;
}

- (void) addOperation:(TSOperation *)operation forIdentifider:(NSString *)identifier
{
    [self addOperation:operation];
    dictionary[identifier] = operation;
    
    __weak typeof (self) weakSelf = self;
    [operation addCancelBlock:^(TSOperation *operation) {
        [weakSelf operationDidFinishForIdentifier:identifier];
    }];
    [operation addCompleteBlock:^(TSOperation *operation) {
        [weakSelf operationDidFinishForIdentifier:identifier];
    }];
}

- (TSOperation *) operationWithIdentifier:(NSString *)identifier
{
    return dictionary[identifier];
}

- (void) operationDidFinishForIdentifier:(NSString *)identifier
{
    [dictionary removeObjectForKey:identifier];
}

@end
