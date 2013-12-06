//
//  TSOperation+Private.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 18.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperation.h"

@interface TSOperation ()

- (void) onComplete;
- (void) onCancel;

- (void) synchronize:(dispatch_block_t)block;

@end
