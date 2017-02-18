//
//  ThumbnailService.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "ThumbnailService.h"
#import "TSCacheManager.h"

#import "TSLoadOperation.h"
#import "TSGenerateOperation.h"
#import "TSOperation+Private.h"

#import "TSOperationQueue.h"

#import "TSRequest+Private.h"
#import "DispatchReleaseMacro.h"
#import "BitmaskMacro.h"

@implementation ThumbnailService {

    TSCacheManager *_placeholderCache;
    TSCacheManager *_thumbnailsCache;

    TSOperationQueue *_queue;

    TSCacheManagerMode _cacheModeFile;
    TSCacheManagerMode _cacheModeMemory;
    TSCacheManagerMode _cacheModeFileAndMemory;

    dispatch_queue_t _serviceQueue;
}

- (id)init
{
    self = [super init];
    if (self) {

        _queue = [[TSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;

        _placeholderCache = [TSCacheManager new];
        _placeholderCache.name = @"Placeholders";

        _thumbnailsCache = [TSCacheManager new];
        _thumbnailsCache.name = @"Thumbnails";

        self.useMemoryCache = YES;
        self.useFileCache = YES;
        self.cacheMemoryLimitInBytes = 3 * 1024 * 1024;

        _serviceQueue = dispatch_queue_create("ThumbnailServiceQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount
{
    _queue.maxConcurrentOperationCount = maxConcurrentOperationCount;
}

- (NSInteger)maxConcurrentOperationCount
{
    return _queue.maxConcurrentOperationCount;
}

- (void)setCacheMemoryLimitInBytes:(NSUInteger)cacheMemoryLimitInBytes
{
    _thumbnailsCache.memoryLimitInBytes = cacheMemoryLimitInBytes;
}

- (NSUInteger)cacheMemoryLimitInBytes
{
    return _thumbnailsCache.memoryLimitInBytes;
}

- (void)dealloc
{
    [_queue cancelAllOperations];
    TSDispatchRelease(_serviceQueue);
}

- (void)setUseFileCache:(BOOL)useFileCache
{
    SET_BITMASK(_cacheModeFile, TSCacheManagerModeFile, useFileCache);
    SET_BITMASK(_cacheModeFileAndMemory, TSCacheManagerModeFile, useFileCache);
}

- (void)setUseMemoryCache:(BOOL)useMemoryCache
{
    SET_BITMASK(_cacheModeMemory, TSCacheManagerModeMemory, useMemoryCache);
    SET_BITMASK(_cacheModeFileAndMemory, TSCacheManagerModeMemory, useMemoryCache);
}

- (BOOL)useMemoryCache
{
    return GET_BITMASK(_cacheModeMemory, TSCacheManagerModeMemory);
}

- (BOOL)useFileCache
{
    return GET_BITMASK(_cacheModeFile, TSCacheManagerModeFile);
}

- (void)setCachesName:(NSString *)cachesName
{
    _placeholderCache.name = [NSString stringWithFormat:@"Placeholders_%@",cachesName];
    _thumbnailsCache.name = [NSString stringWithFormat:@"Thumbnails_%@",cachesName];;
}

- (void)clearFileCache
{
    [_placeholderCache removeAllObjectsForMode:_cacheModeFile];
    [_thumbnailsCache removeAllObjectsForMode:_cacheModeFile];
}

- (BOOL)hasDiskCacheForRequest:(TSRequest *)request
{
    return [_thumbnailsCache objectExistsForKey:request.identifier mode:TSCacheManagerModeFile];
}

- (BOOL)hasMemoryCacheForRequest:(TSRequest *)request
{
    return [_thumbnailsCache objectExistsForKey:request.identifier mode:TSCacheManagerModeMemory];
}

- (void)executeIfHasDiskCacheOrEnqueue:(TSRequest *)request
{
    if ([self hasDiskCacheForRequest:request]) {
        [self executeRequest:request];
    } else {
        [self enqueueRequest:request];
    }
}

#pragma mark - Placeholder methods

- (UIImage *)placeholderFromCacheForSource:(TSSource *)source
{
    NSString *identifier = [source identifier];
    UIImage *placeholder = nil;

    placeholder = [_placeholderCache objectForKey:identifier mode:TSCacheManagerModeFileAndMemory];

    if (!placeholder) {
        placeholder = [source placeholder];
        [_placeholderCache setObject:placeholder forKey:identifier mode:TSCacheManagerModeFileAndMemory];
    }

    return placeholder;
}

- (UIImage *)placeholderFromSource:(TSSource *)source
{
    UIImage *placeholder = nil;

    if (self.shouldCachePlaceholders) {
        placeholder = [self placeholderFromCacheForSource:source];
    }
    else {
        placeholder = [source placeholder];
    }
    return placeholder;
}

#pragma mark - Public methods

- (void)enqueueRequestGroup:(TSRequestGroup *)group
{
    [self enqueueRequestGroup:group andWait:NO];
}

- (void)enqueueRequestGroup:(TSRequestGroup *)group andWait:(BOOL)wait
{
    dispatch_block_t work = ^{

        if ([group isFinished]) {
            return;
        }

        NSArray *requests = [group pullPendingRequests];

        for (TSRequest *request in requests) {
            if (![request isFinished]) {
                [self _enqueueRequest:request];
            }
        }
    };

    if (wait) {
        dispatch_sync(_serviceQueue, work);
    } else {
        dispatch_async(_serviceQueue, work);
    }
}

- (void)enqueueRequest:(TSRequest *)request
{
    [self enqueueRequest:request andWait:NO];
}

- (void)enqueueRequest:(TSRequest *)request andWait:(BOOL)wait
{
    if ([request isFinished]) {
        [self handleWarning:[NSString stringWithFormat:@"Request %@ already finished. Skipping", request]];
        return;
    }

    if (request.group) {
        [self handleWarning:[NSString stringWithFormat:@"You trying to perform request %@, which owned by group %@. Skipping", request, request.group]];
        return;
    }

    dispatch_block_t work = ^{
        [self _enqueueRequest:request];
    };

    if (wait) {
        dispatch_sync(_serviceQueue, work);
    } else {
        dispatch_async(_serviceQueue, work);
    }
}

- (void)executeRequest:(TSRequest *)request
{
    if ([request isFinished]) {
        [self handleWarning:[NSString stringWithFormat:@"Request %@ already finished. Skipping", request]];
        return;
    }

    if (request.group) {
        [self handleWarning:[NSString stringWithFormat:@"You trying to perform request %@, which owned by group %@. Skipping", request, request.group]];
        return;
    }

    [self executePlaceholderRequest:request];
    [self executeThumbnailRequest:request];
}


#pragma mark - Perform request logic

- (void)_enqueueRequest:(TSRequest *)request
{
    [self executePlaceholderRequest:request];
    [self enqueueThumbnailRequest:request];
}

- (void)executePlaceholderRequest:(TSRequest *)request
{
    if ([request needPlaceholder]) {
        UIImage *placeholder = [self placeholderFromSource:request.source];
        [request takePlaceholder:placeholder error:nil];
    }
}

- (void)enqueueThumbnailRequest:(TSRequest *)request
{
    if ([request needThumbnail]) {
        UIImage *thumbnail = [_thumbnailsCache objectForKey:request.identifier mode:TSCacheManagerModeMemory];
        if (thumbnail) {
            [self takeThumbnailInRequest:request withImage:thumbnail error:nil];
        } else {
            [self enqueueOperationForRequest:request];
        }
    }
}

- (void)executeThumbnailRequest:(TSRequest *)request
{
    if ([request needThumbnail]) {
        UIImage *thumbnail = [_thumbnailsCache objectForKey:request.identifier mode:TSCacheManagerModeMemory];
        if (thumbnail) {
            [self takeThumbnailInRequest:request withImage:thumbnail error:nil];
        } else {
            if ([request.source requiresMainThread] && [NSThread isMainThread]) {
                [NSException raise:NSInternalInconsistencyException format:@"You trying to execute request with source %@ on main thread, but this source required main thread to operate. Enqueue or execute from background thraed instead", request.source];
            }
            [self executeOperationForRequest:request];
        }
    }
}

- (void)enqueueOperationForRequest:(TSRequest *)request
{
    TSRequestedOperation *operation = (TSRequestedOperation *)[_queue operationWithIdentifier:request.identifier];

    if (!operation || operation.isCancelled) {
        operation = [self newOperationForRequest:request];
        request.operation = operation;
        [_queue addOperation:operation forIdentifier:request.identifier];
    } else if (operation.isFinished) {
        [self takeThumbnailInRequest:request withImage:operation.result error:operation.error];
    } else {
        request.operation = operation;
    }
}

- (void)executeOperationForRequest:(TSRequest *)request
{
    TSRequestedOperation *operation = [self newOperationForRequest:request];

    [operation main];

    [request takeThumbnail:operation.result error:operation.error];
    request.operation = nil;

    dispatch_async(_serviceQueue, ^{

        TSRequestedOperation *existingOperation = (TSRequestedOperation *)[_queue operationWithIdentifier:request.identifier];

        if (!existingOperation.isCancelled && !existingOperation.isFinished) {
            [existingOperation enumerateRequests:^(TSRequest *anRequest) {
                anRequest.operation = operation;
            }];
        }

        [operation onComplete];
    });
}

#pragma mark - Operations creation

- (TSRequestedOperation *)newOperationForRequest:(TSRequest *)request
{
    TSRequestedOperation *operation;
    if (_cacheModeFile && [_thumbnailsCache objectExistsForKey:request.identifier mode:_cacheModeFile]) {
        operation = [self newOperationToLoadThumbnailForRequest:request];
    } else {
        operation = [self newOperationToGenerateThumbnailForRequest:request];
    }
    return operation;
}

- (TSRequestedOperation *)newOperationToGenerateThumbnailForRequest:(TSRequest *)request
{
    TSRequestedOperation *operation = [[TSGenerateOperation alloc] initWithSource:request.source size:[request sizeToRender]];

    __weak __typeof(self) weakSelf = self;
    [operation addCompleteBlock:^(TSOperation *completeOperation) {
        [weakSelf didGenerateThumbnailForIdentifier:request.identifier fromOperation:(TSRequestedOperation *)completeOperation];
    }];

    return operation;
}

- (TSRequestedOperation *)newOperationToLoadThumbnailForRequest:(TSRequest *)request
{
    TSRequestedOperation *operation = [[TSLoadOperation alloc] initWithKey:request.identifier andCacheManager:_thumbnailsCache];

    __weak __typeof(self) weakSelf = self;
    [operation addCompleteBlock:^(TSOperation *completeOperation) {
        [weakSelf didLoadThumbnailForIdentifier:request.identifier fromOperation:(TSRequestedOperation *)completeOperation];
    }];

    return operation;
}

#pragma mark - Thumbnails Operations completions

- (void)didGenerateThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSRequestedOperation *)operation
{
    if (operation.result && !operation.error) {
        TSCacheManagerMode mode = TSCacheManagerModeNone;
        if ([operation shouldCacheInMemory]) {
            mode |= _cacheModeMemory;
        }
        if ([operation shouldCacheOnDisk]) {
            mode |= _cacheModeFile;
        }
        [_thumbnailsCache setObject:operation.result forKey:identifier mode:mode];
    }

    [self takeThumbnailsForRequestsInOperation:operation];
}

- (void)didLoadThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSRequestedOperation *)operation
{
    if (operation.result && !operation.error && operation.shouldCacheInMemory) {
        [_thumbnailsCache setObject:operation.result forKey:identifier mode:_cacheModeMemory];
    }

    [self takeThumbnailsForRequestsInOperation:operation];
}

- (void)takeThumbnailsForRequestsInOperation:(TSRequestedOperation *)operation
{
    [operation enumerateRequests:^(TSRequest *request) {
        [self takeThumbnailInRequest:request withImage:operation.result error:operation.error];
    }];
}

- (void)takeThumbnailInRequests:(NSSet *)requests withImage:(UIImage *)image error:(NSError *)error
{
    for (TSRequest *request in requests) {
        [self takeThumbnailInRequest:request withImage:image error:error];
    }
}

- (void)takeThumbnailInRequest:(TSRequest *)request withImage:(UIImage *)image error:(NSError *)error
{
    [request takeThumbnail:image error:error];
    [self enqueueRequestGroup:request.group];
}

#pragma mark - Class configuration

- (void)handleWarning:(NSString *)warningString
{
    NSLog(@"ThumbnailService warning: %@", warningString);
}

@end


@implementation ThumbnailService (ExtendedApi)

- (TSCacheManager *)placeholderCache
{
    return _placeholderCache;
}

- (TSCacheManager *)thumbnailsCache
{
    return _thumbnailsCache;
}

@end