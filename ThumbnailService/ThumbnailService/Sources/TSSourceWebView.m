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
@property (atomic) BOOL loading;
@end

@implementation TSSourceWebView {
    NSURL *resourceURL;
    NSString *identifier;
    
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
        
        identifier = [NSString stringWithFormat:@"%d",(unsigned int)[[resourceURL absoluteString] hash]];
    }
    return self;
}

- (BOOL) requiredMainThread
{
    return YES;
}

- (NSString *) identifier
{
    return identifier;
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
    
    CGSize webViewSize;
    webViewSize.width = fmaxf(300, size.width); /* Limit minimum width to 300, since UIWebView will not scaleToFit to smaller width */
    webViewSize.height = (webViewSize.width / size.width) * size.height;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, webViewSize.width, webViewSize.height)];
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
        CGFloat scale = size.width / webViewSize.width;
        
        UIGraphicsBeginImageContextWithOptions(size, NO, 1.0f);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), scale, scale);
        
        [webView.layer renderInContext:UIGraphicsGetCurrentContext()];

        result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        webView = nil;
    });
    
    return result;
}

#pragma mark - WebView delegate

- (void)webViewDidFinishLoad:(UIWebView *)__unused webView
{
    dispatch_group_leave(webViewLoadingGroup);
    self.loading = NO;
}

- (void)webView:(UIWebView *)__unused webView didFailLoadWithError:(NSError *)error
{
    dispatch_group_leave(webViewLoadingGroup);
    loadingError = error;
    self.loading = NO;
}


@end
