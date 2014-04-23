//
//  TSSourceWebView.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 23.04.14.
//  Copyright (c) 2014 Aleksey Garbarev. All rights reserved.
//

#import "TSSourceWebView.h"
#import <UIKit/UIKit.h>

@interface TSSourceWebView ()<UIWebViewDelegate>
@property BOOL loading;
@end

@implementation TSSourceWebView {
    NSURL *resourceURL;
    
    UIWebView *webView;
    dispatch_group_t webViewLoadingGroup;
    NSError *loadingError;
}

- (id) initWithUrl:(NSURL *)_resourceURL
{
    self = [super init];
    if (self) {
        resourceURL = _resourceURL;
        webViewLoadingGroup = dispatch_group_create();
        loadingError = nil;
    }
    return self;
}

- (BOOL) requiredMainThread
{
    return YES;
}

- (NSString *) identifier
{
    return [resourceURL absoluteString];
}

- (UIImage *) placeholder
{
    return [UIImage new];
}

- (UIImage *) thumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError **)error
{
    NSAssert(![NSThread isMainThread], @"TSWebViewService can't be called from main thread, since we have to wait, until UIWebView is loaded, but we can't do that from main thread");
    
    __block UIImage *result = nil;
    
    dispatch_group_enter(webViewLoadingGroup);
    
    self.loading = YES;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        webView.scalesPageToFit = YES;
        NSURLRequest *request = [NSURLRequest requestWithURL:resourceURL];
        webView.delegate = self;
        [webView loadRequest:request];
    });
    
    while (self.loading && !*isCancelled ) {
        [NSThread sleepForTimeInterval:0.1];
    }
    
    if (*isCancelled) {
        [webView stopLoading];
        return nil;
    }

    if (error) {
        *error = loadingError;
    }
    
    if (loadingError) {
        return nil;
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        UIGraphicsBeginImageContextWithOptions(size, NO, 1.0f);

        [webView.layer renderInContext:UIGraphicsGetCurrentContext()];

        result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        webView = nil;
    });
    
    return result;
}

#pragma mark - WebView delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    dispatch_group_leave(webViewLoadingGroup);
    self.loading = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    dispatch_group_leave(webViewLoadingGroup);
    loadingError = error;
    self.loading = NO;
}


@end
