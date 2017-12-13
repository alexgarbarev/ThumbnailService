//
//  NSString+Hash.m
//  Pods
//
//  Created by David Martínez Echavarría on 13/12/17.
//

#import "NSString+Hash.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString(Hash)

-(NSString *)md5 {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

@end
