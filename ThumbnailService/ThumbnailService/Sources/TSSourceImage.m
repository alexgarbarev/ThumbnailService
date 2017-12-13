//
//  TSSourceImage.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 17.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourceImage.h"
#import "NSString+Hash.h"

@implementation TSSourceImage {
    NSURL *_imageURL;
}

- (id)initWithImagePath:(NSString *)imagePath
{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:imagePath];
    return [self initWithImageLocalURL:url];
}

- (id)initWithImageLocalURL:(NSURL *)imageURL
{
    NSParameterAssert([imageURL isFileURL]);
    self = [super init];
    if (self) {
        _imageURL = imageURL;
    }
    return self;
}

- (NSString *)identifier
{
    if (![super identifier]) {
        self.identifier = [[[_imageURL absoluteString] stringByReplacingOccurrencesOfString:NSHomeDirectory() withString:@""] md5];
    }

    return [super identifier];
}

- (UIImage *)placeholder
{
    return [UIImage new];
}

- (UIImage *)thumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    NSUInteger thumbSize = (NSUInteger)fmaxf(size.width, size.height);

    CGDataProviderRef provider = CGDataProviderCreateWithURL((__bridge CFURLRef)_imageURL);

    if (!provider) {
        if (error) {
            *error = [NSError errorWithDomain:@"TSSourceImage" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Can't create CGDataProviderRef. Check filePath or URL"}];
        }
        return nil;
    }

    CGImageSourceRef source;
    @autoreleasepool {
        source = CGImageSourceCreateWithDataProvider(provider, NULL);
    }

    if (*isCancelled) {
        CFRelease(source);
        CFRelease(provider);
        return nil;
    }

    NSDictionary *options = @{(NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
            (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(thumbSize),
            (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES
    };

    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);
    CFRelease(provider);

    if (!imageRef) {
        if (error) {
            *error = [NSError errorWithDomain:@"TSSourceImage" code:1 userInfo:@{NSLocalizedDescriptionKey : @"Can't create thumbnail by CGImageSourceCreateThumbnailAtIndex. Unknown error."}];
        }
        return nil;
    }

    UIImage *toReturn = [UIImage imageWithCGImage:imageRef];

    CFRelease(imageRef);

    return toReturn;
}

@end
