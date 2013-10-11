//
//  TSRequest+Private.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequest.h"
#import "TSOperation.h"

@interface TSRequest ()

@property (nonatomic, weak) TSOperation *operation;

@property (nonatomic, readonly) NSString *identifier;

- (void) takeThumbnail:(UIImage *)image error:(NSError *)error;
- (void) takePlaceholder:(UIImage *)image error:(NSError *)error;

- (BOOL) needPlaceholder;
- (BOOL) needThumbnail;

@end
