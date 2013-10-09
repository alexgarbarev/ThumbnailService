//
//  NSArray+RangeCheck.m
//  StartFX
//
//  Created by Aleksey Garbarev on 24.06.13.
//
//

#import "NSArray+RangeCheck.h"

@implementation NSArray (RangeCheck)

- (BOOL) containsIndex:(NSInteger)index
{
    NSInteger lastIndex = [self count] - 1;
    NSInteger firsrtIndex = 0;
    return index >= firsrtIndex && index <= lastIndex;
}

@end
