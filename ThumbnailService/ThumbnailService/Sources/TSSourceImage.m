//
//  TSSourceImage.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 17.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourceImage.h"

@implementation TSSourceImage {
    NSString *identifier;
    
    NSURL *imageURL;
}

- (id) initWithImagePath:(NSString *)_imagePath
{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:_imagePath];
    return [self initWithImageLocalURL:url];
}

- (id) initWithImageLocalURL:(NSURL *)_imageURL
{
//    NSParameterAssert([_imageURL isFileURL]);
    self = [super init];
    if (self) {
        imageURL = _imageURL;
        identifier = [NSString stringWithFormat:@"%d",[[imageURL absoluteString] hash]];
    }
    return self;
}

- (NSString *)identifier
{
    return identifier;
}

- (UIImage *)placeholder
{
    return [UIImage new];
}

- (UIImage *) thumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    NSUInteger thumbSize = MAX(size.width, size.height);
    
    CGDataProviderRef provider = CGDataProviderCreateWithURL((__bridge CFURLRef)imageURL);
    
    if (!provider) {
        *error = [NSError errorWithDomain:@"TSSourceImage" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Can't create CGDataProviderRef. Check filePath or URL"}];
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
    
    NSDictionary *options = @{ (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                               (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(thumbSize),
                               (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES
                               };
    
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);
    CFRelease(provider);
    
    if (!imageRef) {
        *error = [NSError errorWithDomain:@"TSSourceImage" code:1 userInfo:@{NSLocalizedDescriptionKey : @"Can't create thumbnail by CGImageSourceCreateThumbnailAtIndex. Unknown error."}];
        return nil;
    }
    
    UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
    
    CFRelease(imageRef);
    
    return toReturn;
}

@end
