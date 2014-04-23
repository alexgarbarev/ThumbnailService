//
//  AssetSource.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourceALAsset.h"
#import "ALAsset+Identifier.h"
#import "UIImageView+ImageFrame.h"
#import "TSSourceVideo.h"

#define Retain(object) CFRetain((__bridge CFTypeRef)object)
#define Release(object) CFRelease((__bridge CFTypeRef)object)

typedef struct {
    __unsafe_unretained ALAssetRepresentation *representation;
    __unsafe_unretained NSError *error;
} ProviderCreationInfo;

typedef enum {
    AssetTypeUnknown,
    AssetTypePhoto,
    AssetTypeVideo
} AssetType;

@implementation TSSourceALAsset {
    ALAsset *asset;
    AssetType type;
}

- (id) initWithAsset:(ALAsset *)_asset
{
    self = [super init];
    if (self) {
        NSParameterAssert(_asset);
        asset = _asset;
        [self setupAssetType];
    }
    return self;
}

- (void) setupAssetType
{
    NSString *assetTypeString = [asset valueForProperty:ALAssetPropertyType];
    if ([assetTypeString isEqualToString:ALAssetTypePhoto]) {
        type = AssetTypePhoto;
    } else if ([assetTypeString isEqualToString:ALAssetTypeVideo]){
        type = AssetTypeVideo;
    } else {
        type = AssetTypeUnknown;
    }
}

- (BOOL) isPhoto
{
    return type == AssetTypePhoto;
}

- (BOOL) isVideo
{
    return type == AssetTypeVideo;
}

- (double) videoDuration
{
    double result = 0;
    if ([self isVideo]) {
        result = [[asset valueForProperty:ALAssetPropertyDuration] doubleValue];
    }
    return result;
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

- (UIImage *) thumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    UIImage *result = nil;
    @autoreleasepool {
        if ([self isPhoto]) {
            result = [self imageThumbnailWithSize:size isCancelled:isCancelled error:error];
        } else if ([self isVideo]){
            result = [self videoThumbnailWithSize:size isCancelled:isCancelled error:error];
        } else {
            if (error) {
                *error = [NSError errorWithDomain:@"TSSourceALAsset" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Unknown type of ALAsset"}];
            }
        }
    }
    return result;
}

- (UIImage *) videoThumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    ALAssetRepresentation *representation = [asset defaultRepresentation];
    NSURL *videoURL = [representation url];
    
    TSSourceVideo *videoSource = [[TSSourceVideo alloc] initWithVideoURL:videoURL thumbnailSecond:0];
    
    return [videoSource thumbnailWithSize:size isCancelled:isCancelled error:error];
}

- (UIImage *) imageThumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    NSUInteger thumbSize = (NSUInteger)fmaxf(size.width, size.height);
    ALAssetRepresentation *representation = [asset defaultRepresentation];
    
    CGDataProviderDirectCallbacks callbacks = {
        .version = 0,
        .getBytePointer = NULL,
        .releaseBytePointer = NULL,
        .getBytesAtPosition = GetBytesCallback,
        .releaseInfo = ReleaseInfoCallback,
    };
    
    ProviderCreationInfo *info = malloc(sizeof(ProviderCreationInfo));
    info->representation = Retain(representation);
    info->error = nil;

    CGDataProviderRef provider = CGDataProviderCreateDirect((void *)info, [representation size], &callbacks);
    
    NSError *providerError = info->error;
    
    CGImageSourceRef source;
    @autoreleasepool {
        source = CGImageSourceCreateWithDataProvider(provider, NULL);
    }
    
    if (providerError || *isCancelled) {
        if (error) {
            *error = providerError;
        }
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
        if (error) {
            *error = [NSError errorWithDomain:@"TSSourceALAsset" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Can't create thumbnail by CGImageSourceCreateThumbnailAtIndex. Unknown error."}];
        }
        return nil;
    }
    
    UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
    
    CFRelease(imageRef);

    return toReturn;
}

static size_t GetBytesCallback(void *info, void *buffer, off_t position, size_t count)
{
    ProviderCreationInfo *providerInfo = (ProviderCreationInfo *)info;
    size_t countRead;
    
    ALAssetRepresentation *rep = providerInfo->representation;
    
    NSError *error = nil;
    countRead = [rep getBytes:(uint8_t *)buffer fromOffset:position length:count error:&error];
    
    if (countRead == 0 && error) {
        providerInfo->error = error;
    }
    return countRead;
}

static void ReleaseInfoCallback(void *info)
{
    ProviderCreationInfo *providerInfo = (ProviderCreationInfo *)info;
    Release(providerInfo->representation);
    free(providerInfo);
}

@end
