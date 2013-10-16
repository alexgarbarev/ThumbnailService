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

#define SET_BITMASK(source, mask, enabled) if (enabled) { source |= mask; } else { source &= ~mask; }
#define GET_BITMASK(source, mask) (source & mask)

static BOOL ThumbnailServiceShouldFailOnWarning = NO;
static BOOL ThumbnailServiceShouldPrintWarning = NO;

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
        dispatch_set_target_queue(serviceQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
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
    return [self performRequestGroup:group andWait:NO];
}

- (void) performRequestGroup:(TSRequestGroup *)group andWait:(BOOL)wait
{
    dispatch_block_t work = ^{
        
        if ([group isFinished]) {
            return;
        }
        
        NSArray *requests = [group pullPendingRequests];
        
        for (TSRequest *request in requests) {
            [self _performRequest:request];
        }
    };
    
    if (wait) {
        dispatch_sync(serviceQueue, work);
    } else {
        dispatch_async(serviceQueue, work);
    }
}

- (void) performRequest:(TSRequest *)request
{
    [self performRequest:request andWait:NO];
}

- (void) performRequest:(TSRequest *)request andWait:(BOOL)wait
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
        [self _performRequest:request];
    };
    
    if (wait) {
        dispatch_sync(serviceQueue, work);
    } else {
        dispatch_async(serviceQueue, work);
    }
}

#pragma mark - Peform request logic

- (void) _performRequest:(TSRequest *)request
{
    [self performPlaceholderRequest:request];
    [self performThumbnailRequest:request];
}

- (void) performPlaceholderRequest:(TSRequest *)request
{
    if ([request needPlaceholder]) {
        UIImage *placeholder = [self placeholderFromSource:request.source];
        [request takePlaceholder:placeholder error:nil];
    }
}

- (void) performThumbnailRequest:(TSRequest *)request
{
    if ([request needThumbnail]) {
        UIImage *thumbnail = [thumbnailsCache objectForKey:request.identifier mode:TSCacheManagerModeMemory];
        
        if (!thumbnail) {
            [self enqueueOperationForRequest:request];
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
        [request setOperation:operation andWait:YES];
        [queue addOperation:operation forIdentifider:request.identifier];
    } else if (operation.isFinished){
        [self takeThumbnailInRequest:request withImage:operation.result error:operation.error];
    } else {
        [request setOperation:operation andWait:YES];
    }
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

    __weak typeof (self) weakSelf = self;
    [operation addCompleteBlock:^(TSOperation *operation) {
        [weakSelf didGenerateThumbnailForIdentifier:request.identifier fromOperation:operation];
    }];
    
    return operation;
}

- (TSOperation *) newOperationToLoadThumbnailForRequest:(TSRequest *)request
{
    TSOperation *operation = [[TSLoadOperation alloc] initWithKey:request.identifier andCacheManager:thumbnailsCache];

    __weak typeof (self) weakSelf = self;
    [operation addCompleteBlock:^(TSOperation *operation) {
        [weakSelf didLoadThumbnailForIdentifier:request.identifier fromOperation:operation];
    }];

    return operation;
}

#pragma mark - Thumbnails Operations completions

- (void) didGenerateThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSOperation *)operation
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

- (void) didLoadThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSOperation *)operation
{
    if (operation.result && !operation.error && operation.shouldCacheInMemory) {
        [thumbnailsCache setObject:operation.result forKey:identifier mode:cacheModeMemory];
    }
    
    [self takeThumnbailsForRequestsInOperation:operation];
}

- (void) takeThumnbailsForRequestsInOperation:(TSOperation *)operation
{
    [operation enumerationRequests:^(TSRequest *request) {
        [self takeThumbnailInRequest:request withImage:operation.result error:operation.error];
    } onQueue:serviceQueue];
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

#pragma mark - Class configuration

- (void) handleWarning:(NSString *)warningString
{
    if (ThumbnailServiceShouldPrintWarning) {
        NSLog(@"ThumbnailService warning: %@",warningString);
    }
    if (ThumbnailServiceShouldFailOnWarning) {
        NSAssert(NO, @"");
    }
}

+ (void)setShouldFailOnWarning:(BOOL)shouldFail
{
    ThumbnailServiceShouldFailOnWarning = shouldFail;
}

+ (BOOL)shouldFailOnWarning
{
    return ThumbnailServiceShouldFailOnWarning;
}

+ (void) setShouldPrintWarnings:(BOOL)shouldPrint
{
    ThumbnailServiceShouldPrintWarning = shouldPrint;
}

+ (BOOL) shouldPrintWarnings
{
    return ThumbnailServiceShouldPrintWarning;
}


@end
