//
//  TSSource.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TSSource : NSObject

- (NSString *) identifier;

- (UIImage *) placeholder; 
- (UIImage *) thumbnailWithSize:(CGSize)size;

@end


/*
    Placeholder is something which can be fetched fast to show user while thumbnail loading. 
    Placeholder loading performs in foreground.
 
    Thumbnail is preview of big image. Thumbnail loading performs in background.
 */
