//
//  RequestsTests.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 13.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ThumbnailService.h"
#import "TSSourceTest.h"

#import "TestUtils.h"
#import "TSRequest+Private.h"

@interface RequestsTests : XCTestCase

@end

@implementation RequestsTests {
    ThumbnailService *thumbnailService;
}

- (void)setUp
{
    [super setUp];
    
    thumbnailService = [[ThumbnailService alloc] init];
}

- (void)tearDown
{
    [super tearDown];
}


- (void) testRequest
{
    __block BOOL thumbnailCalled = 0;
    __block BOOL placeholderCalled = 0;

    
    TSSourceTest *source = [TSSourceTest new];
    
    TSRequest *request = [TSRequest new];
    request.source = source;
    request.size = CGSizeMake(100, 100);
    request.priority = NSOperationQueuePriorityHigh;
    request.shouldCastCompletionsToMainThread = NO;
    [request setPlaceholderCompletion:^(UIImage *result, NSError *error) {
        placeholderCalled = YES;
    }];
    [request setThumbnailCompletion:^(UIImage *result, NSError *error) {
        thumbnailCalled = YES;
    }];
    
    [thumbnailService performRequest:request];
    
    WaitAndCallInBackground(0.3, ^{
        [source fire];
    });
    
    [request waitUntilFinished];
    
    XCTAssert(thumbnailCalled, @"Called: %d", thumbnailCalled);
    XCTAssert(placeholderCalled, @"Called: %d",placeholderCalled);
}

- (void) testRequestOnMainThread
{
    __block BOOL thumbnailCalled = 0;
    __block BOOL placeholderCalled = 0;
    
    TSSourceTest *source = [TSSourceTest new];
    
    TSRequest *request = [TSRequest new];
    request.source = source;
    request.size = CGSizeMake(100, 100);
    request.priority = NSOperationQueuePriorityHigh;
    request.shouldCastCompletionsToMainThread = NO;
    [request setPlaceholderCompletion:^(UIImage *result, NSError *error) {
        placeholderCalled = YES;
    }];
    [request setThumbnailCompletion:^(UIImage *result, NSError *error) {
        thumbnailCalled = YES;
    }];
    
    WaitAndCallInBackground(0.3, ^{
        [source fire];
    });
    
    [thumbnailService performRequestOnMainThread:request];
    
    XCTAssert(thumbnailCalled, @"Called: %d", thumbnailCalled);
    XCTAssert(placeholderCalled, @"Called: %d",placeholderCalled);
}

- (void) testRequestOnSameSource
{
    __block int thumbnailCalled = 0;
    __block int placeholderCalled = 0;
    
    TSRequestCompletion placeholderCompletion = ^(UIImage *result, NSError *error) {
        placeholderCalled++;
    };
    TSRequestCompletion thumbnailCompletion = ^(UIImage *result, NSError *error) {
        thumbnailCalled++;
    };
    
    TSSourceTest *source = [TSSourceTest new];
    
    TSRequest *request1 = [TSRequest new];
    request1.source = source;
    request1.size = CGSizeMake(300, 300);
    request1.priority = NSOperationQueuePriorityNormal;
    request1.shouldCastCompletionsToMainThread = NO;
    [request1 setPlaceholderCompletion:placeholderCompletion];
    [request1 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request2 = [TSRequest new];
    request2.source = source;
    request2.size = CGSizeMake(300, 300);
    request2.priority = NSOperationQueuePriorityHigh;
    request2.shouldCastCompletionsToMainThread = NO;
    [request2 setPlaceholderCompletion:placeholderCompletion];
    [request2 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request3 = [TSRequest new];
    request3.source = source;
    request3.size = CGSizeMake(300, 300);
    request3.priority = NSOperationQueuePriorityLow;
    request3.shouldCastCompletionsToMainThread = NO;
    [request3 setPlaceholderCompletion:placeholderCompletion];
    [request3 setThumbnailCompletion:thumbnailCompletion];
    
    [thumbnailService performRequest:request1];
    XCTAssert(request1.operation.queuePriority == NSOperationQueuePriorityNormal, @"");
    
    
    WaitAndCallInBackground(0.3, ^{
        [thumbnailService performRequest:request2];
        XCTAssert(request1.operation == request2.operation, @"");
        XCTAssert(request1.operation.queuePriority == NSOperationQueuePriorityHigh, @"");
    });
    
    WaitAndCallInBackground(0.6, ^{
        [thumbnailService performRequest:request3];
        XCTAssert(request2.operation == request3.operation, @"");
        XCTAssert(request1.operation.queuePriority == NSOperationQueuePriorityHigh, @"");
    });

    
    WaitAndCallInBackground(0.9, ^{
        [source fire];
    });

    [request1 waitUntilFinished];
    [request2 waitUntilFinished];
    [request3 waitUntilFinished];
    
    XCTAssert(thumbnailCalled == 3, @"Called: %d", thumbnailCalled);
    XCTAssert(placeholderCalled == 3, @"Called: %d",placeholderCalled);
}

- (void) testRequestOnSameSourceAndCancel
{
    __block int thumbnailCalled = 0;
    __block int placeholderCalled = 0;
    
    TSRequestCompletion placeholderCompletion = ^(UIImage *result, NSError *error) {
        placeholderCalled++;
    };
    TSRequestCompletion thumbnailCompletion = ^(UIImage *result, NSError *error) {
        thumbnailCalled++;
    };
    
    TSSourceTest *source = [TSSourceTest new];
    
    TSRequest *request1 = [TSRequest new];
    request1.source = source;
    request1.size = CGSizeMake(300, 300);
    request1.priority = NSOperationQueuePriorityNormal;
    request1.shouldCastCompletionsToMainThread = NO;
    [request1 setPlaceholderCompletion:placeholderCompletion];
    [request1 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request2 = [TSRequest new];
    request2.source = source;
    request2.size = CGSizeMake(300, 300);
    request2.priority = NSOperationQueuePriorityHigh;
    request2.shouldCastCompletionsToMainThread = NO;
    [request2 setPlaceholderCompletion:placeholderCompletion];
    [request2 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request3 = [TSRequest new];
    request3.source = source;
    request3.size = CGSizeMake(300, 300);
    request3.priority = NSOperationQueuePriorityLow;
    request3.shouldCastCompletionsToMainThread = NO;
    [request3 setPlaceholderCompletion:placeholderCompletion];
    [request3 setThumbnailCompletion:thumbnailCompletion];
    
    [thumbnailService performRequest:request1];
    XCTAssert(request1.operation.queuePriority == NSOperationQueuePriorityNormal, @"");
    
    
    WaitAndCallInBackground(0.3, ^{
        [thumbnailService performRequest:request2];
        XCTAssert(request1.operation == request2.operation, @"");
        XCTAssert(request1.operation.queuePriority == NSOperationQueuePriorityHigh, @"");
    });
    
    WaitAndCallInBackground(0.5, ^{
        [request2 cancel];
        XCTAssert(request1.operation.queuePriority == NSOperationQueuePriorityNormal, @"");
    });
    
    WaitAndCallInBackground(0.8, ^{
        [thumbnailService performRequest:request3];
        XCTAssert(request1.operation == request3.operation, @"");
        XCTAssert(request1.operation.queuePriority == NSOperationQueuePriorityNormal, @"%d",request1.operation.queuePriority);
    });
    
    
    WaitAndCallInBackground(1.0, ^{
        [source fire];
    });
    
    [request1 waitUntilFinished];
    [request2 waitUntilFinished];
    [request3 waitUntilFinished];
    
    XCTAssert(thumbnailCalled == 2, @"Called: %d", thumbnailCalled);
    XCTAssert(placeholderCalled == 3, @"Called: %d",placeholderCalled);
}

- (void) testRequestOnSameSourceAndCancelOperation
{
    __block int thumbnailCalled = 0;
    __block int placeholderCalled = 0;
    
    TSRequestCompletion placeholderCompletion = ^(UIImage *result, NSError *error) {
        placeholderCalled++;
    };
    TSRequestCompletion thumbnailCompletion = ^(UIImage *result, NSError *error) {
        thumbnailCalled++;
    };
    
    TSSourceTest *source = [TSSourceTest new];
    
    TSRequest *request1 = [TSRequest new];
    request1.source = source;
    request1.size = CGSizeMake(300, 300);
    request1.priority = NSOperationQueuePriorityNormal;
    request1.shouldCastCompletionsToMainThread = NO;
    [request1 setPlaceholderCompletion:placeholderCompletion];
    [request1 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request2 = [TSRequest new];
    request2.source = source;
    request2.size = CGSizeMake(300, 300);
    request2.priority = NSOperationQueuePriorityHigh;
    request2.shouldCastCompletionsToMainThread = NO;
    [request2 setPlaceholderCompletion:placeholderCompletion];
    [request2 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request3 = [TSRequest new];
    request3.source = source;
    request3.size = CGSizeMake(300, 300);
    request3.priority = NSOperationQueuePriorityLow;
    request3.shouldCastCompletionsToMainThread = NO;
    [request3 setPlaceholderCompletion:placeholderCompletion];
    [request3 setThumbnailCompletion:thumbnailCompletion];

    [thumbnailService performRequest:request1];

    TSOperation *operation = request1.operation;
    XCTAssert(operation.queuePriority == NSOperationQueuePriorityNormal, @"");
    
    WaitAndCallInBackground(0.3, ^{
        [thumbnailService performRequest:request2];
        XCTAssert(operation == request2.operation, @"");
        XCTAssert(operation.queuePriority == NSOperationQueuePriorityHigh, @"");
    });
    
    WaitAndCallInBackground(0.5, ^{
        [thumbnailService performRequest:request3];
        [request2 cancel];
        XCTAssert(operation.queuePriority == NSOperationQueuePriorityNormal, @"");
    });
    
    WaitAndCallInBackground(0.8, ^{
        [request1 cancel];
        [request3 cancel];
    });
    
    WaitAndCallInBackground(0.9, ^{
        [source fire];
    });
    
    [request1 waitUntilFinished];
    [request2 waitUntilFinished];
    [request3 waitUntilFinished];
    
    XCTAssert([operation isCancelled], @"Must be cancelled if no request waiting");

    XCTAssert(thumbnailCalled == 0, @"Called: %d", thumbnailCalled);
    XCTAssert(placeholderCalled == 3, @"Called: %d",placeholderCalled);
}

@end
