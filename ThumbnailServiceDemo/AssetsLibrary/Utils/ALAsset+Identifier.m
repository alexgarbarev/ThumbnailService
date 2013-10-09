//
//  ALAsset+Identifier.m
//  PixMarx
//
//  Created by Aleksey Garbarev on 03.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "ALAsset+Identifier.h"
#import <objc/runtime.h>

@implementation ALAsset (Identifier)

- (void) storeIdentifier:(NSString *)identifier
{
    objc_setAssociatedObject(self, "identifier", identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *) storedIdentifier
{
    return objc_getAssociatedObject(self, "identifier");
}

- (NSString *)identifier
{
    NSString *identifier = [self storedIdentifier];
    if (!identifier) {        
        NSURL *url = [[self defaultRepresentation] url];
        identifier = [url absoluteString];
        identifier = [identifier stringByReplacingOccurrencesOfString:@"/" withString:@""];
        identifier = [identifier stringByReplacingOccurrencesOfString:@":" withString:@""];
        [self storeIdentifier:identifier];
    }
    return identifier;
}

- (BOOL)isEqual:(ALAsset *)object
{
    return [object.identifier isEqualToString:self.identifier];
}

@end
