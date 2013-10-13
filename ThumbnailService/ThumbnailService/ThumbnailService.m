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

#import "TSOperationQueue.h"

#import "TSRequest+Private.h"
#import "TSOperation+Private.h"

#define SET_BITMASK(source, mask, enabled) if (enabled) { source |= mask; } else { source &= ~mask; }
#define GET_BITMASK(source, mask) (source & mask)


@implementation ThumbnailService {
    
    TSCacheManager *placeholderCache;
    TSCacheManager *thumbnailsCache;
    
    TSOperationQueue *queue;
    
    TSCacheManagerMode cacheModeFile;
    TSCacheManagerMode cacheModeMemory;
    TSCacheManagerMode cacheModeFileAndMemory;
}

- (id)init
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
    }
    return self;
}

- (void)setUseFileCache:(BOOL)useFileCache
{
    SET_BITMASK(cacheModeFile, TSCacheManagerModeFile, useFileCache);
    SET_BITMASK(cacheModeFileAndMemory, TSCacheManagerModeFile, useFileCache);
}

- (void)setUseMemoryCache:(BOOL)useMemoryCache
{
    SET_BITMASK(cacheModeMemory, TSCacheManagerModeMemory, useMemoryCache);
    SET_BITMASK(cacheModeFileAndMemory, TSCacheManagerModeMemory, useMemoryCache);
}

- (BOOL)useMemoryCache
{
    return GET_BITMASK(cacheModeMemory, TSCacheManagerModeMemory);
}

- (BOOL)useFileCache
{
    return GET_BITMASK(cacheModeFile, TSCacheManagerModeFile);
}

- (void) clearFileCache
{
    [placeholderCache removeAllObjectsForMode:cacheModeFile];
    [thumbnailsCache removeAllObjectsForMode:cacheModeFile];
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

- (void) performRequestGroup:(TSRequestGroup *)group
{
    NSArray *requests = [group pullPendingRequests];
    
    if (!requests) {
        return;
    }
        
    for (TSRequest *request in requests) {
        if ([group shouldPerformOnMainQueueRequest:request]) {
            [self performRequestOnMainThread:request];
        } else {
            [self performRequest:request];
        }
    }
}

- (void) performRequestOnMainThread:(TSRequest *)request
{
    [self performRequest:request onMainThread:YES];
}

- (void) performRequest:(TSRequest *)request
{
    [self performRequest:request onMainThread:NO];
}

- (void) performRequest:(TSRequest *)request onMainThread:(BOOL)runOnMainThread
{
    if ([request isRequestFinished]) {
        @throw [NSException exceptionWithName:@"Invalid request exception" reason:[NSString stringWithFormat:@"Request %@ already finished", request] userInfo:nil];
        return;
    }
    [self performPlaceholderRequest:request];
    
    [self performThumbnailRequest:request onMainThread:runOnMainThread];
}

- (void) performPlaceholderRequest:(TSRequest *)request
{
    if ([request needPlaceholder]) {
        UIImage *placeholder = [self placeholderFromSource:request.source];
        [request takePlaceholder:placeholder error:nil];
    }
}

- (void) performThumbnailRequest:(TSRequest *)request onMainThread:(BOOL)runOnMainThread
{
    if ([request needThumbnail]) {
        UIImage *thumbnail = [thumbnailsCache objectForKey:request.identifier mode:TSCacheManagerModeMemory];
        
        if (!thumbnail)
        {
            if (runOnMainThread) {
                [self peformOperationOnMainThreadForRequest:request];
            } else {
                [self enqueueOperationForRequest:request];
            }
        }
        else {
            [self takeThumbnailInRequest:request withImage:thumbnail error:nil];
        }
    }
}

- (void) enqueueOperationForRequest:(TSRequest *)request
{
    TSOperation *operation = [queue operationWithIdentifier:request.identifier];
    
    if (!operation) {
        operation = [self newOperationForRequest:request];
        request.operation = operation;
        [queue addOperation:operation forIdentifider:request.identifier];
    } else if (operation.isFinished){
        [request takeThumbnail:operation.result error:operation.error];
    } else {
        request.operation = operation;
    }
}

- (void) peformOperationOnMainThreadForRequest:(TSRequest *)request
{
    dispatch_block_t performBlock = ^{
        TSOperation *operation = [self newOperationForRequest:request];
        request.operation = operation;
        [operation runOnMainThread];
    };
    
    if ([NSThread isMainThread]) {
        performBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), performBlock);
    };
}

#pragma mark - Operations creation

- (TSOperation *) newOperationForRequest:(TSRequest *)request
{
    TSOperation *operation;
    if (cacheModeFile && [thumbnailsCache objectExistsForKey:request.identifier mode:cacheModeFile]) {
        operation = [self newOperationToLoadThumbnailForRequest:request];
    } else {
        operation = [self newOperationToGenerateThumbnailForRequest:request];
    }
    return operation;
}

- (TSOperation *) newOperationToGenerateThumbnailForRequest:(TSRequest *)request
{
    TSOperation *operation = [[TSGenerateOperation alloc] initWithSource:request.source size:[request sizeToRender]];

    [operation addCompleteBlock:^(TSOperation *operation) {
        [self didGenerateThumbnailForIdentifier:request.identifier fromOperation:operation];
    }];
    
    return operation;
}

- (TSOperation *) newOperationToLoadThumbnailForRequest:(TSRequest *)request
{
    TSOperation *operation = [[TSLoadOperation alloc] initWithKey:request.identifier andCacheManager:thumbnailsCache];

    [operation addCompleteBlock:^(TSOperation *operation) {
        [self didLoadThumbnailForIdentifier:request.identifier fromOperation:operation];
    }];

    return operation;
}

#pragma mark - Thumbnails Operations completions

- (void) didGenerateThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSOperation *)operation
{
    if (operation.result && !operation.error) {
        [thumbnailsCache setObject:operation.result forKey:identifier mode:cacheModeFileAndMemory];
    }

    [self takeThumbnailInRequests:operation.requests withImage:operation.result error:operation.error];
}

- (void) didLoadThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSOperation *)operation
{
    if (operation.result && !operation.error) {
        [thumbnailsCache setObject:operation.result forKey:identifier mode:cacheModeMemory];
    }
    
    [self takeThumbnailInRequests:operation.requests withImage:operation.result error:operation.error];
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
    [self performRequestGroup:request.group];
}


@end
