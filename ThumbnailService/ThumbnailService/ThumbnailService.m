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

#import "TSOperationQueue.h"

#import "TSRequest+Private.h"

@implementation ThumbnailService {
    NSCache *placeholderMemoryCache;
    TSFileCache *placeholderFileCache;
    
    NSCache *thumbnailsMemoryCache;
    TSFileCache *thumbnailsFileCache;
    
    TSOperationQueue *queue;
}

- (id)init
{
    self = [super init];
    if (self) {
        queue = [[TSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        
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

- (void) performRequests:(NSSet *)requests
{
    for (TSRequest *request in requests) {
        [self performRequest:request];
    }
}

- (void) performRequest:(TSRequest *)request
{
    if ([request needPlaceholder]) {
        UIImage *placeholder = [self placeholderFromSource:request.source];
        [request takePlaceholder:placeholder error:nil];
    }
    
    if ([request needThumbnail]) {
        UIImage *thumbnail = [thumbnailsMemoryCache objectForKey:request.identifier];
        
        if (!thumbnail)
        {
            TSOperation *operation = [queue operationWithIdentifier:request.identifier];
            
            if (!operation) {
                operation = [self newOperationForRequest:request];
                request.operation = operation;
                [queue addOperation:operation forIdentifider:request.identifier];
            } else {
                request.operation = operation;
            }
        }
        else {
            [request takeThumbnail:thumbnail error:nil];
        }
    }
}

#pragma mark - Operations creation

- (TSOperation *) newOperationForRequest:(TSRequest *)request
{
    TSOperation *operation;
    if ([thumbnailsFileCache objectExistsForKey:request.identifier]) {
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
    TSOperation *operation = [[TSLoadOperation alloc] initWithKey:request.identifier andFileCache:thumbnailsFileCache];

    [operation addCompleteBlock:^(TSOperation *operation) {
        [self didLoadThumbnailForIdentifier:request.identifier fromOperation:operation];
    }];

    return operation;
}

#pragma mark - Operations completions

- (void) didGenerateThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSOperation *)operation
{
    if (operation.result && !operation.error) {
        [thumbnailsFileCache setObject:operation.result forKey:identifier];
        [thumbnailsMemoryCache setObject:operation.result forKey:identifier];
    }

    [self callCompletionInRequests:operation.requests withImage:operation.result error:operation.error];
}

- (void) didLoadThumbnailForIdentifier:(NSString *)identifier fromOperation:(TSOperation *)operation
{
    if (operation.result && !operation.error) {
        [thumbnailsMemoryCache setObject:operation.result forKey:identifier];
    }
    
    [self callCompletionInRequests:operation.requests withImage:operation.result error:operation.error];
}

- (void) callCompletionInRequests:(NSSet *)requests withImage:(UIImage *)image error:(NSError *)error
{
    for (TSRequest *request in requests) {
        [request takeThumbnail:image error:error];
    }
}

@end
