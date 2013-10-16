//
//  TSRequest+Private.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequest.h"
#import "TSOperation.h"
#import "TSRequestGroup.h"

@interface TSRequest ()

@property (nonatomic, weak) TSOperation *operation;

@property (nonatomic, readonly) NSString *identifier;

@property (nonatomic, strong) TSRequestGroup *group;

- (void) takeThumbnail:(UIImage *)image error:(NSError *)error;
- (void) takePlaceholder:(UIImage *)image error:(NSError *)error;

- (BOOL) needPlaceholder;
- (BOOL) needThumbnail;

- (void) cancelAndWait:(BOOL)wait;

- (CGSize) sizeToRender;

- (void)setOperation:(TSOperation *)operation andWait:(BOOL)wait;

@end
