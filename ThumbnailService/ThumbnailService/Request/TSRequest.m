//
//  TSRequest.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequest.h"
#import "TSRequest+Private.h"

@interface TSRequest ()

@property (nonatomic, copy) TSRequestCompletion placeholderBlock;
@property (nonatomic, copy) TSRequestCompletion thumbnailBlock;

@end

@implementation TSRequest {
    BOOL needUpdateIdentifier;
    NSString *_cachedIdentifier;
    
    dispatch_semaphore_t liveSemaphore;
}

- (id) init
{
    self = [super init];
    if (self) {
        [self requestDidStarted];
    }
    return self;
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

- (void) setOperation:(TSOperation *)operation
{
    if (_operation) {
        [_operation removeRequest:self];
    }
    
    _operation = operation;
    
    if (_operation) {
        [_operation addRequest:self];
    }
}

#pragma mark - Modifying request reqirements

- (void)setPriority:(NSOperationQueuePriority)priority
{
    _priority = priority;
    [self.operation updatePriority];
}

- (void) cancel
{
    self.operation = nil;
    self.thumbnailBlock = nil;
    self.placeholderBlock = nil;
    [self requestDidFinish];
    [self.group didCancelRequest:self];
}

#pragma mark - Life-cycle

- (void) requestDidStarted
{
    liveSemaphore = dispatch_semaphore_create(0);
}

- (void) requestDidFinish
{
    dispatch_semaphore_signal(liveSemaphore);
}

- (void) waitUntilFinished
{
    dispatch_semaphore_wait(liveSemaphore, DISPATCH_TIME_FOREVER);
}

#pragma mark - Callbacks

- (void) setPlaceholderCompletion:(TSRequestCompletion)placeholderBlock
{
    self.placeholderBlock = placeholderBlock;
}

- (void) setThumbnailCompletion:(TSRequestCompletion)thumbnailBlock
{
    self.thumbnailBlock = thumbnailBlock;
}

- (BOOL) needPlaceholder
{
    return self.placeholderBlock != nil;
}

- (BOOL) needThumbnail
{
    return self.thumbnailBlock != nil;
}

- (void) takePlaceholder:(UIImage *)image error:(NSError *)error
{
    if (self.placeholderBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
           self.placeholderBlock(image, error);
        });
    }
}

- (void) takeThumbnail:(UIImage *)image error:(NSError *)error
{
    if (self.thumbnailBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
           self.thumbnailBlock(image, error); 
        });
    }
    [self requestDidFinish];
    [self.group didFinishRequest:self];
}

@end
