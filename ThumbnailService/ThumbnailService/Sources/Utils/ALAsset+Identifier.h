//
//  ALAsset+Identifier.h
//  PixMarx
//
//  Created by Aleksey Garbarev on 03.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAsset (Identifier)

@property (nonatomic, readonly) NSString *identifier;

@end
