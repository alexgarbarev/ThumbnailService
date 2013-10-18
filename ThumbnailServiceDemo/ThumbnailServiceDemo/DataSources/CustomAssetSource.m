//
//  AssetSource.m
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 18.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "CustomAssetSource.h"

@implementation CustomAssetSource


+ (NSDateFormatter *) sharedDateFormatter
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return dateFormatter;
}

- (UIImage *) drawDuration:(double)duration onImage:(UIImage *)image
{
    NSString *durationString = [[[self class] sharedDateFormatter] stringFromDate:[NSDate dateWithTimeIntervalSince1970:duration]];
    
    NSString *desciptionString = [NSString stringWithFormat:@"Video. Duration: %@",durationString];
    
    CGFloat fontSize = image.size.height / 16.0f;
    CGRect descriptionRect = (CGRect){CGPointZero, CGSizeMake(image.size.width, fontSize * 1.2)};
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 1.0f);
    [image drawAtPoint:CGPointZero];
    [[UIColor whiteColor] set];
    [desciptionString drawInRect:descriptionRect withFont:[UIFont systemFontOfSize:fontSize] lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    [[UIColor colorWithWhite:0.0 alpha:0.3] set];
    CGContextFillRect(UIGraphicsGetCurrentContext(), descriptionRect);
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();

    
    return result;
}

- (UIImage *)placeholder
{
    UIImage *placeholder = [super placeholder];
    if ([self isVideo]) {
        placeholder = [self drawDuration:[super videoDuration] onImage:placeholder];
    }
    return placeholder;
}

- (UIImage *)thumbnailWithSize:(CGSize)size isCancelled:(const BOOL *)isCancelled error:(NSError *__autoreleasing *)error
{
    UIImage *thumbnail = [super thumbnailWithSize:size isCancelled:isCancelled error:error];
    if ([self isVideo]) {
        thumbnail = [self drawDuration:[self videoDuration] onImage:thumbnail];
    }
    return thumbnail;
}

@end
