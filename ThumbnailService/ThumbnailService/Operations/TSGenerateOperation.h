//
//  TSGenerateOperation.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRequestedOperation.h"
#import "TSSource.h"

@interface TSGenerateOperation : TSRequestedOperation

- (id)initWithSource:(TSSource *)source size:(CGSize)size;

@end
