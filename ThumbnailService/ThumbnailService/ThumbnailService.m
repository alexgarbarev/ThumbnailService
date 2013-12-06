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
#import "TSRequestedOperation.h"

#define SET_BITMASK(source, mask, enabled) if (enabled) { source |= mask; } else { source &= ~mask; }
#define GET_BITMASK(source, mask) (source & mask)

@implementation ThumbnailService {
    
    TSCacheManager *placeholderCache;
    TSCacheManager *thumbnailsCache;
    
    TSOperationQueue *queue;
    
    TSCacheManagerMode cacheModeFile;
    TSCacheManagerMode cacheModeMemory;
    TSCacheManagerMode cacheModeFileAndMemory;
    
    dispatch_queue_t serviceQueue;
}

- (id) init
{
    self = [super init];
    if (self) {
        
        queue = [[TSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        
        placeholderCache = [TSCacheManager new];
        placeholderCache.name = @"Placeholders";
        
        thumbnailsCache = [TSCacheManager new];
        thumbnailsCache.name = @"Thumbnails";
        
        self.useMemoryCache = YES;
        self.useFileCache = YES;
        self.cacheMemoryLimitInBytes = 3 * 1024 * 1024;
        
        serviceQueue = dispatch_queue_create("ThumbnailServiceQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void) setCacheMemoryLimitInBytes:(NSUInteger)cacheMemoryLimitInBytes
{
    thumbnailsCache.memoryLimitInBytes = cacheMemoryLimitInBytes;
}

- (NSUInteger) cacheMemoryLimitInBytes
{
    return thumbnailsCache.memoryLimitInBytes;
}

- (void) dealloc
{
    [queue cancelAllOperations];
    dispatch_release(serviceQueue);
}

- (void) setUseFileCache:(BOOL)useFileCache
{
    SET_BITMASK(cacheModeFile, TSCacheManagerModeFile, useFileCache);
    SET_BITMASK(cacheModeFileAndMemory, TSCacheManagerModeFile, useFileCache);
}

- (void) setUseMemoryCache:(BOOL)useMemoryCache
{
    SET_BITMASK(cacheModeMemory, TSCacheManagerModeMemory, useMemoryCache);
    SET_BITMASK(cacheModeFileAndMemory, TSCacheManagerModeMemory, useMemoryCache);
}

- (BOOL) useMemoryCache
{
    return GET_BITMASK(cacheModeMemory, TSCacheManagerModeMemory);
}

- (BOOL) useFileCache
{
    return GET_BITMASK(cacheModeFile, TSCacheManagerModeFile);
}

- (void) clearFileCache
{
    [placeholderCache removeAllObjectsForMode:cacheModeFile];
    [thumbnailsCache removeAllObjectsForMode:cacheModeFile];
}

- (BOOL) hasDiskCacheForRequest:(TSRequest *)request
{
    return [thumbnailsCache objectExistsForKey:request.identifier mode:TSCacheManagerModeFile];
}

- (BOOL) hasMemoryCacheForRequest:(TSRequest *)request
{
    return [thumbnailsCache objectExistsForKey:request.identifier mode:TSCacheManagerModeMemory];
}

#pragma mark - Placeholder methods

- (UIImage *) placeholderFromCacheForSource:(TSSource *)source
{
    NSString *identifier = [source identifier];
    UIImage *placeholder = nil;
    
    placeholder = [placeholderCache objectForKey:identifier mode:TSCacheManagerModeFileAndMemory];
    
    if (!placeholder) {
        placeholder = [source placeholder];
        [placeholderCache setObject:placeholder forKey:identifier mode:TSCacheManagerModeFileAndMemory];
    }
    
    return placeholder;
}

- (UIImage *) placeholderFromSource:(TSSource *)source
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

- (void) enqueueRequestGroup:(TSRequestGroup *)group
{
    return [self enqueueRequestGroup:group andWait:NO];
}

- (void) enqueueRequestGroup:(TSRequestGroup *)group andWait:(BOOL)wait
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
        dispatch_sync(serviceQueue, work);
    } else {
        dispatch_async(serviceQueue, work);
    }
}

- (void) enqueueRequest:(TSRequest *)request
{
    [self enqueueRequest:request andWait:NO];
}

- (void) enqueueRequest:(TSRequest *)request andWait:(BOOL)wait
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
        dispatch_sync(serviceQueue, work);
    } else {
        dispatch_async(serviceQueue, work);
    }
}

- (void) executeRequest:(TSRequest *)request
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


#pragma mark - Peform request logic

- (void) _enqueueRequest:(TSRequest *)request
{
    [self executePlaceholderRequest:request];
    [self enqueueThumbnailRequest:request];
}

- (void) executePlaceholderRequest:(TSRequest *)request
{
    if ([request needPlaceholder]) {
        UIImage *placeholder = [self placeholderFromSource:request.source];
        [request takePlaceholder:placeholder error:nil];
    }
}

- (void) enqueueThumbnailRequest:(TSRequest *)request
{
    if ([request needThumbnail]) {
        UIImage *thumbnail = [thumbnailsCache objectForKey:request.identifier mode:TSCacheManagerModeMemory];
        if (thumbnail) {
            [self takeThumbnailInRequest:request withImage:thumbnail error:nil];
        } else {
            [self enqueueOperationForRequest:request];
        }
    }
}

- (void) executeThumbnailRequest:(TSRequest *)request
{
    if ([request needThumbnail]) {
        UIImage *thumbnail = [thumbnailsCache objectForKey:request.identifier mode:TSCacheManagerModeMemory];
        if (thumbnail) {
            [self takeThumbnailInRequest:request withImage:thumbnail error:nil];
        } else {
            [self executeOperationForRequest:request];
        }
    }
}

- (void) enqueueOperationForRequest:(TSRequest *)request
{
    TSRequestedOperation *operation = (TSRequestedOperation *)[queue operationWithIdentifier:request.identifier];

    if (!operation) {
        operation = [self newOperationForRequest:request];
        [request setOperation:operation andWait:YES];
        [queue addOperation:operation forIdentifider:request.identifier];
    } else if (operation.isFinished){
        [self takeThumbnailInRequest:request withImage:operation.result error:operation.error];
    } else {
        [request setOperation:operation andWait:YES];
    }
}

- (void) executeOperationForRequest:(TSRequest *)request
{
    TSRequestedOperation *operation = [self newOperationForRequest:request];

    [operation main];
    
    [request takeThumbnail:operation.result error:operation.error];
    request.operation = nil;
    
    dispatch_async(serviceQueue, ^{
    
        TSRequestedOperation *existingOperation = (TSRequestedOperation *)[queue operationWithIdentifier:request.identifier];
        
        if (!existingOperation.isCancelled && !existingOperation.isFinished) {
            [existingOperation enumerationRequests:^(TSRequest *anRequest) {
                anRequest.operation = operation;
            }];
        }
        
        [operation onComplete];
    });
}

#pragma mark - Operations creation

- (TSRequestedOperation *) newOperationForRequest:(TSRequest *)request
{
    TSRequestedOperation *operation;
    if (cacheModeFile && [thumbnailsCache objectExistsForKey:request.identifier mode:cacheModeFile]) {
        operation = [self newOperationToLoadThumbnailForRequest:request];
    } else {
        operation = [self newOperationToGenerateThumbnailForRequest:request];
    }
    return operation;
}

- (TSRequestedOperation *) newOperationToGenerateThumbnailForRequest:(TSRequest *)request
{
    TSRequestedOperation *operation = [[TSGenerateOperation alloc] initWithSource:request.source size:[request sizeToRender]];

    __weak typeof (self) weakSelf = self;
    [operation addCompleteBlock:^(TSOperation *operation) {
        [weakSelf didGenerateThumbnailForIdentifier:request.identifier fromOperation:(TSRequestedOperation *)operation];
    }];
    
    return operation;
}

- (TSRequestedOperation *) newOperationToLoadThumbnailForRequest:(TSRequest *)request
{
    TSRequestedOperation *operation = [[TSLoadOperation alloc] initWithKey:request.identifier andCacheManager:thumbnailsCache];

    __weak typeof (self) weakSelf = self;
    [operation addCompleteBlock:^(TSOperation *operation) {
        [weakSelf didLoadThumbnailForIdentifier:request.identifier fromOperation:(TSRequestedOperation *)operation];
    }];

    return operation;
}

#pragma mark - Thumbnails Operations completions

- (void) didGenerateThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSRequestedOperation *)operation
{
    if (operation.result && !operation.error)
    {
        TSCacheManagerMode mode = 0;
        if ([operation shouldCacheInMemory]) {
            mode |= cacheModeMemory;
        }
        if ([operation shouldCacheOnDisk]) {
            mode |= cacheModeFile;
        }
        [thumbnailsCache setObject:operation.result forKey:identifier mode:mode];
    }

    [self takeThumnbailsForRequestsInOperation:operation];
}

- (void) didLoadThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSRequestedOperation *)operation
{
    if (operation.result && !operation.error && operation.shouldCacheInMemory) {
        [thumbnailsCache setObject:operation.result forKey:identifier mode:cacheModeMemory];
    }
    
    [self takeThumnbailsForRequestsInOperation:operation];
}

- (void) takeThumnbailsForRequestsInOperation:(TSRequestedOperation *)operation
{
    [operation enumerationRequests:^(TSRequest *request) {
        [self takeThumbnailInRequest:request withImage:operation.result error:operation.error];
    }];
}

- (void) takeThumbnailInRequests:(NSSet *)requests withImage:(UIImage *)image error:(NSError *)error
{
    for (TSRequest *request in requests) {
        [self takeThumbnailInRequest:request withImage:image error:error];
    }
}

- (void) takeThumbnailInRequest:(TSRequest *)request withImage:(UIImage *)image error:(NSError *)error
{
    [request takeThumbnail:image error:error];
    [self enqueueRequestGroup:request.group];
}

#pragma mark - Class configuration

- (void) handleWarning:(NSString *)warningString
{
    NSLog(@"ThumbnailService warning: %@",warningString);
}


@end
