//
//  AssetSource.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourceALAsset.h"
#import "ALAsset+Identifier.h"

#import <ImageIO/ImageIO.h>

NSError *lastError;

@implementation TSSourceALAsset {
    ALAsset *asset;
}

- (id) initWithAsset:(ALAsset *)_asset
{
    self = [super init];
    if (self) {
        asset = _asset;
    }
    return self;
}

- (NSString *) identifier
{
    return asset.identifier;
}

- (UIImage *) placeholder
{
    CGImageRef placeholder = [asset aspectRatioThumbnail];;
    return [UIImage imageWithCGImage:placeholder];
}

- (UIImage *) thumbnailWithSize:(CGSize)size isCancelled:(BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    NSUInteger thumbSize = MAX(size.width, size.height);
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    
    CGDataProviderDirectCallbacks callbacks = {
        .version = 0,
        .getBytePointer = NULL,
        .releaseBytePointer = NULL,
        .getBytesAtPosition = getAssetBytesCallback,
        .releaseInfo = releaseAssetCallback,
    };
    
    CGDataProviderRef provider = CGDataProviderCreateDirect((void *)CFBridgingRetain(rep), [rep size], &callbacks);
    
    
    CGImageSourceRef source;
    @autoreleasepool {
        source = CGImageSourceCreateWithDataProvider(provider, NULL);
    }
    if (lastError || *isCancelled) {
        *error = lastError;
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
        return nil;
    }
    
    UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
    
    CFRelease(imageRef);

    return toReturn;
}

static size_t getAssetBytesCallback(void *info, void *buffer, off_t position, size_t count) {
    size_t countRead;
    
    ALAssetRepresentation *rep = (__bridge id)info;
    
    NSError *error = nil;
    countRead = [rep getBytes:(uint8_t *)buffer fromOffset:position length:count error:&error];
    
    if (countRead == 0 && error) {
        lastError = error;
    }
    return countRead;
}

static void releaseAssetCallback(void *info)
{
    CFRelease(info);
}

@end
