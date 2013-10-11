//
//  TSOperationQueue.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 11.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSOperation.h"

@interface TSOperationQueue : NSOperationQueue

- (void) addOperation:(TSOperation *)operation forIdentifider:(NSString *)identifier;
- (TSOperation *) operationWithIdentifier:(NSString *)identifier;

@end
