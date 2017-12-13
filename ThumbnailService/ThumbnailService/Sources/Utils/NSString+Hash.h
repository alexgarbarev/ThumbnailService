//
//  NSString+Hash.h
//  Pods
//
//  Created by David Martínez Echavarría on 13/12/17.
//

#import <Foundation/Foundation.h>

@interface NSString (Hash)

/**
 Hashes a given string with the MD5 algorithm.
 */
@property (nonatomic, readonly) NSString *md5;

@end
