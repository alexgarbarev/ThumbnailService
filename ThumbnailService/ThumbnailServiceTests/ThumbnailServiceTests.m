//
//  ThumbnailServiceTests.m
//  ThumbnailServiceTests
//
//  Created by Aleksey Garbarev on 11.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ThumbnailService.h"

#import "TSSourceTest.h"

#import "TSRequestGroupSequence.h"

@interface ThumbnailServiceTests : XCTestCase

@end

dispatch_queue_t testingBackgroundQueue;

@implementation ThumbnailServiceTests {
    ThumbnailService *thumbnailService;
}

- (void)setUp
{
    [super setUp];
    
    thumbnailService = [[ThumbnailService alloc] init];
    testingBackgroundQueue = dispatch_queue_create("testing queue", NULL);
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
    
}

void WaitAndCallInBackground(NSTimeInterval timeToWait, dispatch_block_t block)
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToWait * NSEC_PER_SEC));
    dispatch_after(popTime, testingBackgroundQueue, block);
}

- (void) testSimpleCompletion
{
    __block BOOL completionCalled = NO;
    __block BOOL placeholderCalled = NO;
    
    TSSourceTest *source = [TSSourceTest new];
    
    TSRequest *request = [TSRequest new];
    request.source = source;
    request.size = CGSizeMake(200, 200);
    request.shouldCastCompletionsToMainThread = NO;

    [request setPlaceholderCompletion:^(UIImage *result, NSError *error) {
        NSLog(@"Placeholder complete with result: %@. Error: %@",result,error);
        placeholderCalled = YES;
    }];
    [request setThumbnailCompletion:^(UIImage *result, NSError *error) {
        NSLog(@"Thumbnail complete with result: %@. Error: %@",result,error);
        completionCalled = YES;
    }];
    
    WaitAndCallInBackground(2, ^{
        [source fire];
    });
    
    [thumbnailService performRequest:request];
    [request waitUntilFinished];
    
//    [thumbnailService performRequestOnCurrentThread:request];
    
    XCTAssert(completionCalled, @"");
    XCTAssert(placeholderCalled, @"");

}

- (void) testMultipleRequests
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
    request1.size = CGSizeMake(100, 100);
    request1.priority = NSOperationQueuePriorityHigh;
    [request1 setPlaceholderCompletion:placeholderCompletion];
    [request1 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request2 = [TSRequest new];
    request2.source = source;
    request2.size = CGSizeMake(200, 200);
    request2.priority = NSOperationQueuePriorityNormal;
    [request2 setPlaceholderCompletion:placeholderCompletion];
    [request2 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request3 = [TSRequest new];
    request3.source = source;
    request3.size = CGSizeMake(300, 300);
    request3.priority = NSOperationQueuePriorityLow;
    [request3 setPlaceholderCompletion:placeholderCompletion];
    [request3 setThumbnailCompletion:thumbnailCompletion];
    
    request1.shouldCastCompletionsToMainThread = NO;
    request2.shouldCastCompletionsToMainThread = NO;
    request3.shouldCastCompletionsToMainThread = NO;
    
    TSRequestGroupSequence *group = [TSRequestGroupSequence new];
    [group addRequest:request1 runOnMainThread:NO];
    [group addRequest:request2 runOnMainThread:NO];
    [group addRequest:request3 runOnMainThread:NO];
    
    [thumbnailService performRequestGroup:group];
    
//    [thumbnailService performRequest:request1];
//    [thumbnailService performRequest:request2];
//    [thumbnailService performRequest:request3];

    
//    WaitAndCallInBackground(1, ^{
//        [request1 cancel];
//    });
//    
//    WaitAndCallInBackground(1, ^{
//        [request3 cancel];
//    });
//
//    WaitAndCallInBackground(2, ^{
//        [request3 cancel];
//    });
    
    WaitAndCallInBackground(1, ^{
        [source fire];
    });
    
    WaitAndCallInBackground(1, ^{
        [source fire];
    });
    
    WaitAndCallInBackground(1, ^{
        [source fire];
    });
    
//    [request1 waitUntilFinished];
//    [request2 waitUntilFinished];
//    [request3 waitUntilFinished];
    
    [group waitUntilFinished];
    
    XCTAssert(thumbnailCalled == 3, @"Called: %d", thumbnailCalled);
    XCTAssert(placeholderCalled == 3, @"Called: %d",placeholderCalled);
    
}



@end
