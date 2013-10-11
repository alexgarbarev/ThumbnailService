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

@property (nonatomic, strong) TSOperation *managedOperation;
@property (nonatomic, weak)   TSOperation *expectedOperation;


@property (nonatomic) BOOL isCanceled;

@property (nonatomic, readonly) NSString *identifier;


- (void) callCompetionWithImage:(UIImage *)image;

@end
