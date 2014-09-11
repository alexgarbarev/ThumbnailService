//
//  TSRequestGroupSequence.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 13.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSRequestGroup.h"

@interface TSRequestGroupSequence : TSRequestGroup

- (void)addRequest:(TSRequest *)request;

@end
