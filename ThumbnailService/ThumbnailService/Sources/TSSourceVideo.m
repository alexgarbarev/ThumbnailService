//
//  TSSourceVideo.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 18.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSSourceVideo.h"
#import "UIImageView+ImageFrame.h"

@implementation TSSourceVideo {
    NSString *identifier;
    NSURL *videoURL;
    CGFloat thumbnailSecond;
    AVURLAsset *_videoAsset;
}

- (id)initWithVideoFilePath:(NSString *)filePath thumbnailSecond:(CGFloat)second
{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:filePath];
    return [self initWithVideoURL:url thumbnailSecond:second];
}

- (id)initWithVideoURL:(NSURL *)url thumbnailSecond:(CGFloat)second
{
    self = [super init];
    if (self) {
        thumbnailSecond = second;
        videoURL = url;
        identifier = [NSString stringWithFormat:@"%d-%g", (unsigned int)[[videoURL absoluteString] hash], second];
    }
    return self;
}

- (NSString *)identifier
{
    return [super identifier] ? [super identifier] : identifier;
}

- (UIImage *)placeholder
{
    return [UIImage new];
}

- (AVURLAsset *)videoAsset
{
    if (!_videoAsset) {
        _videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    }
    return _videoAsset;
}

- (double)videoDuration
{
    return CMTimeGetSeconds([self videoAsset].duration);
}

- (UIImage *)thumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{

    /* Generate image from video */
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:[self videoAsset]];
    imageGenerator.appliesPreferredTrackTransform = YES;
    NSError *generationError = nil;
    CMTime time = CMTimeMakeWithSeconds(thumbnailSecond, 600);

    CGImageRef generatedImageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&generationError];


    if (generationError) {
        *error = generationError;
        return nil;
    }

    if (!generatedImageRef) {
        *error = [NSError errorWithDomain:@"TSSourceALAsset" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Can't copy image from video by copyCGImageAtTime:actualTime:error. Unknown error."}];
        return nil;
    }


    if (*isCancelled) {
        return nil;
    }

    /* Scale image to match request */
    CGSize generatedImageSize = CGSizeMake(CGImageGetWidth(generatedImageRef), CGImageGetHeight(generatedImageRef));

    CGPoint resultScales = [UIImageView imageScalesForImageSize:generatedImageSize boundingRect:(CGRect){CGPointZero, size} contentMode:UIViewContentModeScaleAspectFit];

    CGSize renderSize = CGSizeMake(generatedImageSize.width * resultScales.x, generatedImageSize.height * resultScales.y);

    UIGraphicsBeginImageContextWithOptions(renderSize, YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGContextTranslateCTM(context, 0, -renderSize.height);
    CGContextDrawImage(context, (CGRect){CGPointZero, renderSize}, generatedImageRef);
    UIImage *toReturn = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CFRelease(generatedImageRef);

    return toReturn;
}

@end
