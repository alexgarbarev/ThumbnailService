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
        self.shouldCastCompletionsToMainThread = YES;
        self.shouldAdjustSizeToScreenScale = YES;
    }
    return self;
}

- (NSString *) identifier
{
    if (needUpdateIdentifier || !_cachedIdentifier) {
        CGSize size = [self sizeToRender];
        _cachedIdentifier = [[NSString alloc] initWithFormat:@"%@_%gx%g",[self.source identifier], size.width, size.height];
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

- (CGSize)sizeToRender
{
    CGFloat scale = [[UIScreen mainScreen] scale];
    return CGSizeMake(_size.width * scale, _size.height * scale);
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
    self.thumbnailBlock = nil;
    self.placeholderBlock = nil;
    
    if (![self isRequestFinished]) {
        [self requestDidFinish];
        [self.group didCancelRequest:self];
    }
    
    self.operation = nil;
}

#pragma mark - Life-cycle

- (void) requestDidStarted
{
    liveSemaphore = dispatch_semaphore_create(0);
}

- (void) requestDidFinish
{
    if (liveSemaphore != NULL) {
        dispatch_semaphore_signal(liveSemaphore);
        liveSemaphore = NULL;
    }
}

- (BOOL) isRequestFinished
{
    return liveSemaphore == NULL;
}

- (void) waitUntilFinished
{
    if (![self isRequestFinished]) {
        dispatch_semaphore_wait(liveSemaphore, DISPATCH_TIME_FOREVER);
    }
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
    [self performCompletion:self.placeholderBlock withResult:image error:error];
}

- (void) takeThumbnail:(UIImage *)image error:(NSError *)error
{
    [self performCompletion:self.thumbnailBlock withResult:image error:error];

    if (![self isRequestFinished]) {
        [self requestDidFinish];
        [self.group didFinishRequest:self];
    }
}

- (void) performCompletion:(TSRequestCompletion)completion withResult:(UIImage *)image error:(NSError *)error
{
    if (completion) {
        if (self.shouldCastCompletionsToMainThread) {
            if ([NSThread isMainThread]) {
                completion(image, error);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(image, error);
                });
            }
        } else {
            completion(image, error);
        }
    }
}

@end
