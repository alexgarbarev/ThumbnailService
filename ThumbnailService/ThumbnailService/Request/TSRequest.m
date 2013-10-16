//
//  TSRequest.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequest.h"
#import "TSRequest+Private.h"

typedef NS_ENUM(NSInteger, TSRequestState) {
    TSRequestStateNotStarted       = 0,
    TSRequestStateEnqueued         = 1 << 1,
    TSRequestStateGotPlaceholder   = 1 << 2,
    TSRequestStateGotThumbnail     = 1 << 3,
    TSRequestStateCancelled        = 1 << 4
};

@interface TSRequest ()

@property (nonatomic, copy) TSRequestCompletion placeholderBlock;
@property (nonatomic, copy) TSRequestCompletion thumbnailBlock;

@property (nonatomic) dispatch_semaphore_t finishWaitSemaphore;
@property (nonatomic) dispatch_semaphore_t placeholderWaitSemaphore;

@property (nonatomic) TSRequestState state;

@end

@implementation TSRequest {
    BOOL needUpdateIdentifier;
    NSString *_cachedIdentifier;
    
    dispatch_queue_t requestDispatchQueue;
}

@synthesize finishWaitSemaphore = _finishWaitSemaphore;
@synthesize placeholderWaitSemaphore = _placeholderWaitSemaphore;

- (id) init
{
    self = [super init];
    if (self) {
        requestDispatchQueue = dispatch_queue_create("TSRequestQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(requestDispatchQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        
        self.shouldCastCompletionsToMainThread = YES;
        self.shouldAdjustSizeToScreenScale = YES;
        self.shouldCacheOnDisk = YES;
        self.shouldCacheInMemory = YES;
        
        self.finishWaitSemaphore = dispatch_semaphore_create(0);
        self.placeholderWaitSemaphore = dispatch_semaphore_create(0);
        
        self.state = TSRequestStateNotStarted;
    }
    return self;
}

- (void) dealloc
{
    dispatch_release(self.finishWaitSemaphore);
    dispatch_release(self.placeholderWaitSemaphore);
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
    [self setOperation:operation andWait:NO];
}

- (void) setOperation:(TSOperation *)operation andWait:(BOOL)wait
{
    if (_operation) {
        [_operation removeRequest:self andWait:wait];
    }
    
    _operation = operation;
    
    if (_operation) {
        [_operation addRequest:self andWait:wait];
    }
    
    if (operation) {
        self.state |= TSRequestStateEnqueued;
    } else {
        self.state &= ~TSRequestStateEnqueued;
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
    [self cancelAndWait:NO];
}

- (void) cancelAndWait:(BOOL)wait
{
    self.thumbnailBlock = nil;
    self.placeholderBlock = nil;
    
    [self setOperation:nil andWait:wait];
    
    self.state |= TSRequestStateCancelled;
}

#pragma mark - Request State

- (void) printState:(TSRequestState)state
{
    if (state & TSRequestStateEnqueued) NSLog(@"Enqueud");
    if (state & TSRequestStateCancelled) NSLog(@"Canceled");
    if (state & TSRequestStateGotPlaceholder) NSLog(@"Got placeholder");
    if (state & TSRequestStateGotThumbnail) NSLog(@"Got thumbnail");
    if (state == TSRequestStateNotStarted) NSLog(@"Not started");
    
}

- (void) setState:(TSRequestState)newState
{
    dispatch_sync(requestDispatchQueue, ^{
        TSRequestState oldState = _state;
        _state = newState;
        
        if (newState & TSRequestStateGotPlaceholder && !(oldState & TSRequestStateGotPlaceholder)) {
            dispatch_semaphore_signal(self.placeholderWaitSemaphore);
        }
        
        if ([self isDidFinishInState:newState afterState:oldState]) {
            dispatch_semaphore_signal(self.finishWaitSemaphore);
            
            if (newState & TSRequestStateCancelled) {
                [self.group didCancelRequest:self];
            } else {
                [self.group didFinishRequest:self];
            }
        }


    });
}

- (BOOL) isDidFinishInState:(TSRequestState)newState afterState:(TSRequestState)oldState
{
    return [self isFinishedState:newState] ;
}

- (BOOL) isFinished
{
    return [self isFinishedState:self.state];
}

- (BOOL) isFinishedState:(TSRequestState)state
{
    BOOL isFinished = (state != TSRequestStateNotStarted);
    
    if ([self needPlaceholder]) {
        isFinished &= (state & TSRequestStateGotPlaceholder) > 0;
    }
    
    if ([self needThumbnail]) {
        isFinished &= (state & TSRequestStateGotThumbnail) > 0;
    }
    
    isFinished |= state & TSRequestStateCancelled;
    
    
    return isFinished;
}

- (BOOL) isStarted
{
    return self.state != TSRequestStateNotStarted;
}

#pragma mark -

- (void) waitUntilFinished
{
    if ([self needThumbnail] || [self needPlaceholder]) {
        dispatch_semaphore_wait(self.finishWaitSemaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void) waitPlaceholder
{
    if ([self needPlaceholder]) {
        dispatch_semaphore_wait(self.placeholderWaitSemaphore, DISPATCH_TIME_FOREVER);
    }
}

#pragma mark -

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
    self.state |= TSRequestStateGotPlaceholder;
}

- (void) takeThumbnail:(UIImage *)image error:(NSError *)error
{
    [self performCompletion:self.thumbnailBlock withResult:image error:error];
    self.state |= TSRequestStateGotThumbnail;
}

#pragma mark - Completions

- (void) setPlaceholderCompletion:(TSRequestCompletion)placeholderBlock
{
    NSAssert(![self isStarted], @"Can't change placeholderBlock, cause request already started");
    self.placeholderBlock = placeholderBlock;
}

- (void) setThumbnailCompletion:(TSRequestCompletion)thumbnailBlock
{
    NSAssert(![self isStarted], @"Can't change thumbnailBlock, cause request already started");
    self.thumbnailBlock = thumbnailBlock;
}

- (void) performCompletion:(TSRequestCompletion)completion withResult:(UIImage *)image error:(NSError *)error
{
    if (completion) {
        if (self.shouldCastCompletionsToMainThread) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image, error);
            });
        } else {
            completion(image, error);
        }
    }
}

@end
