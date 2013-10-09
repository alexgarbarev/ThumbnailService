//
//  TSSource.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSSource : NSObject

- (NSString *) identifier;

- (UIImage *) placeholder;
- (UIImage *) thumbnailWithSize:(CGSize)size;

@end
