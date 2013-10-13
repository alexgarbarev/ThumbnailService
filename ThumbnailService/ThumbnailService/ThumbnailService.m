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

@implementation ThumbnailService {
    
    TSCacheManager *placeholderCache;
    TSCacheManager *thumbnailsCache;
    
    TSOperationQueue *queue;
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
    }
    return self;
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

- (void) performRequestGroup:(TSRequestGroup *)group
{
    NSArray *requests = [group pullPendingRequests];
    
    if (!requests) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        
        for (TSRequest *request in requests) {
            if ([group shouldPerformOnMainQueueRequest:request]) {
                [self performRequestOnCurrentThread:request];
            } else {
                [self performRequest:request];
            }
        }
        
    });
}

- (void) performRequestOnCurrentThread:(TSRequest *)request
{
    [self performPlaceholderRequest:request];
    
    [self performThumbnailRequest:request onCurrentThread:YES];
}

- (void) performRequest:(TSRequest *)request
{
    [self performPlaceholderRequest:request];
    
    [self performThumbnailRequest:request onCurrentThread:NO];
}

- (void) performPlaceholderRequest:(TSRequest *)request
{
    if ([request needPlaceholder]) {
        UIImage *placeholder = [self placeholderFromSource:request.source];
        [request takePlaceholder:placeholder error:nil];
    }
}

- (void) performThumbnailRequest:(TSRequest *)request onCurrentThread:(BOOL)runOnCurrentThread
{
    if ([request needThumbnail]) {
        UIImage *thumbnail = [thumbnailsCache objectForKey:request.identifier mode:TSCacheManagerModeMemory];
        
        if (!thumbnail)
        {
            if (runOnCurrentThread) {
                [self peformOperationForRequest:request];
            } else {
                [self enqueueOperationForRequest:request];
            }
        }
        else {
            [request takeThumbnail:thumbnail error:nil];
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

- (void) peformOperationForRequest:(TSRequest *)request
{
    TSOperation *operation = [self newOperationForRequest:request];
    request.operation = operation;
    [operation start];
    [operation onComplete];
}

#pragma mark - Operations creation

- (TSOperation *) newOperationForRequest:(TSRequest *)request
{
    TSOperation *operation;
    if ([thumbnailsCache objectExistsForKey:request.identifier mode:TSCacheManagerModeFile]) {
        operation = [self newOperationToLoadThumbnailForRequest:request];
    } else {
        operation = [self newOperationToGenerateThumbnailForRequest:request];
    }
    return operation;
}

- (TSOperation *) newOperationToGenerateThumbnailForRequest:(TSRequest *)request
{
    TSOperation *operation = [[TSGenerateOperation alloc] initWithSource:request.source size:request.size];

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
        [thumbnailsCache setObject:operation.result forKey:identifier mode:TSCacheManagerModeFileAndMemory];
    }

    [self takeThumbnailInRequests:operation.requests withImage:operation.result error:operation.error];
}

- (void) didLoadThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSOperation *)operation
{
    if (operation.result && !operation.error) {
        [thumbnailsCache setObject:operation.result forKey:identifier mode:TSCacheManagerModeMemory];
    }
    
    [self takeThumbnailInRequests:operation.requests withImage:operation.result error:operation.error];
}

- (void) takeThumbnailInRequests:(NSSet *)requests withImage:(UIImage *)image error:(NSError *)error
{
    for (TSRequest *request in requests) {
        [request takeThumbnail:image error:error];

        [self performRequestGroup:request.group];
    }
}


@end
