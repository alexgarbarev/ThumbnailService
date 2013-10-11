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

@interface ThumbnailServiceTests : XCTestCase

@end

@implementation ThumbnailServiceTests {
    ThumbnailService *thumbnailService;
}

- (void)setUp
{
    [super setUp];
    
    thumbnailService = [[ThumbnailService alloc] init];
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

- (void) testSimpleCompletion
{
    __block BOOL completionCalled = NO;
    __block BOOL placeholderCalled = NO;
    
    TSRequest *request = [TSRequest new];
    request.source = [TSSourceTest new];
    request.size = CGSizeMake(200, 200);

    
    request.placeholderBlock = ^(UIImage *result){
        placeholderCalled = YES;
    };
    
    request.completionBlock = ^(UIImage *result){
        completionCalled = YES;
    };
    
    [thumbnailService performRequest:request];
    
    [request waitUntilFinished];
    
    XCTAssert(completionCalled, @"");
    XCTAssert(placeholderCalled, @"");
}

@end
