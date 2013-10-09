//
//  ALAsset+Images.m
//  PixMarx
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "ALAsset+Images.h"
#import <ImageIO/ImageIO.h>

@implementation ALAsset (Images)

- (UIImage *) imageToDisplay
{
    return [UIImage imageWithCGImage:[[self defaultRepresentation] fullScreenImage]];
}

- (UIImage *) image
{
    ALAssetRepresentation *representation = [self defaultRepresentation];
    UIImageOrientation orientation = (UIImageOrientation)[representation orientation];
    return [UIImage imageWithCGImage:[representation fullResolutionImage] scale:1.0f orientation:orientation];
}

- (UIImage *) thumbnailWithType:(AssetThumbnailType)thumbType
{
    CGImageRef thumbnail = NULL;
    if (thumbType == AssetThumbnailTypeAspectRatio) {
        thumbnail = [self aspectRatioThumbnail];
    } else {
        thumbnail = [self thumbnail];
    }
    return [UIImage imageWithCGImage:thumbnail];
}

- (UIImage *) thumbnailWithSize:(NSUInteger)size
{
    NSParameterAssert(size > 0);
    
    ALAssetRepresentation *rep = [self defaultRepresentation];
    
    CGDataProviderDirectCallbacks callbacks = {
        .version = 0,
        .getBytePointer = NULL,
        .releaseBytePointer = NULL,
        .getBytesAtPosition = getAssetBytesCallback,
        .releaseInfo = releaseAssetCallback,
    };
    
    CGDataProviderRef provider = CGDataProviderCreateDirect((void *)CFBridgingRetain(rep), [rep size], &callbacks);
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    
    NSDictionary *options = @{ (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                               (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(size),
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
    ALAssetRepresentation *rep = (__bridge id)info;
    
    NSError *error = nil;
    size_t countRead = [rep getBytes:(uint8_t *)buffer fromOffset:position length:count error:&error];
    
    if (countRead == 0 && error) {
        // We have no way of passing this info back to the caller, so we log it, at least.
        NSLog(@"thumbnailForAsset:maxPixelSize: got an error reading an asset: %@", error);
    }
    
    return countRead;
}

static void releaseAssetCallback(void *info)
{
    CFRelease(info);
}
@end
