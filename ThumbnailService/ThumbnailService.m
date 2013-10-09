//
//  ThumbnailService.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "ThumbnailService.h"
#import "TSFileCache.h"

#import "TSLoadOperation.h"
#import "TSGenerateOperation.h"

#import "TSRequest+Private.h"

@implementation ThumbnailService {
    NSCache *placeholderMemoryCache;
    TSFileCache *placeholderFileCache;
    
    NSCache *thumbnailsMemoryCache;
    TSFileCache *thumbnailsFileCache;
    
    NSOperationQueue *queue;
    NSMutableDictionary *requestsInProgress;
}

- (id)init
{
    self = [super init];
    if (self) {
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        
        requestsInProgress = [NSMutableDictionary new];
        
        thumbnailsFileCache = [[TSFileCache alloc] init];
        [thumbnailsFileCache setName:@"Thumbnails"];
        
        placeholderFileCache = [[TSFileCache alloc] init];
        [placeholderFileCache setName:@"Placeholders"];
        
        placeholderMemoryCache = [[NSCache alloc] init];
        
        thumbnailsMemoryCache = [[NSCache alloc] init];
    }
    return self;
}

#pragma mark - Placeholder methods

- (UIImage *) placeholderFromCacheForSource:(TSSource *)source
{
    NSString *identifier = [source identifier];
    UIImage *placeholder = nil;
    
    placeholder = [placeholderMemoryCache objectForKey:identifier];
    
    if (!placeholder) {
        placeholder = [placeholderFileCache objectForKey:identifier];
        [placeholderMemoryCache setObject:placeholder forKey:identifier];
    }
    if (!placeholder) {
        placeholder = [source placeholder];
        [placeholderMemoryCache setObject:placeholder forKey:identifier];
        [placeholderFileCache setObject:placeholder forKey:identifier];
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

- (void) performRequests:(NSArray *)requests
{
    for (TSRequest *request in requests) {
        [self performRequest:request];
    }
}

- (void) performRequest:(TSRequest *)request
{
    if (request.isCanceled) {
        return;
    }
    
    UIImage *placeholder = [self placeholderFromSource:request.source];
    request.placeholderBlock(placeholder);
    
    UIImage *thumbnail = [thumbnailsMemoryCache objectForKey:request.identifier];
    
    if (!thumbnail)
    {
        if ([self isOperationInProgressForRequest:request]) {
            [self linkOperationInProgressWithRequest:request];
        }
        else {
            [self addOperationForRequest:request];
        }
    }
    else {
        request.completionBlock(thumbnail);
    }
}

#pragma mark -

- (void) linkOperationInProgressWithRequest:(TSRequest *)request
{
    TSRequest *requestInProgress = requestsInProgress[request.identifier];
    request.expectedOperation = requestInProgress.managedOperation;
}

- (BOOL) isOperationInProgressForRequest:(TSRequest *)request
{
    return requestsInProgress[request.identifier] != nil;
}

- (void) addOperationForRequest:(TSRequest *)request
{
    TSOperation *operation;
    if ([thumbnailsFileCache objectExistsForKey:request.identifier]) {
        operation = [self newOperationToLoadThumbnailForRequest:request];
    } else {
        operation = [self newOperationToGenerateThumbnailForRequest:request];
    }
    operation.queuePriority = request.priority;
    [queue addOperation:operation];
    
    request.managedOperation = operation;
    
    requestsInProgress[request.identifier] = request;
}

#pragma mark - Operations creation

- (TSOperation *) newOperationToGenerateThumbnailForRequest:(TSRequest *)request
{
    TSOperation *operation = [[TSGenerateOperation alloc] initWithSource:request.source size:request.size];
    __weak typeof (operation) weakObject = operation;
    operation.completionBlock = ^{
        [self didGenerateThumbnail:weakObject.result forRequest:request];
    };
    operation.cancellationBlock = ^{
        [self didCancelOperationForRequest:request];
    };
    return operation;
}

- (TSOperation *) newOperationToLoadThumbnailForRequest:(TSRequest *)request
{
    TSOperation *operation = [[TSLoadOperation alloc] initWithKey:request.identifier andFileCache:thumbnailsFileCache];
    __weak typeof (operation) weakObject = operation;
    operation.completionBlock = ^{
        [self didLoadThumbnail:weakObject.result forRequest:request];
    };
    operation.cancellationBlock = ^{
        [self didCancelOperationForRequest:request];
    };
    return operation;
}

#pragma mark - Operations completions

- (void) didGenerateThumbnail:(UIImage *)thumbnail forRequest:(TSRequest *)request
{
    [thumbnailsFileCache setObject:thumbnail forKey:request.identifier];
    [self performRequests:request.managedOperation.expectantRequests];
    [requestsInProgress removeObjectForKey:request.identifier];
    request.completionBlock(thumbnail);
}

- (void) didLoadThumbnail:(UIImage *)thumbnail forRequest:(TSRequest *)request
{
    [self performRequests:request.managedOperation.expectantRequests];
    [requestsInProgress removeObjectForKey:request.identifier];
    request.completionBlock(thumbnail);
}

- (void) didCancelOperationForRequest:(TSRequest *)request
{
    [self performRequests:request.managedOperation.expectantRequests];
    [requestsInProgress removeObjectForKey:request.identifier];
}
@end
