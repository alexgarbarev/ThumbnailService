//
//  NSObject+Notifications.m
//  Eyeris
//
//  Created by Ivan Zezyulya on 18.11.11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "NotificationUtils.h"

@implementation NSObject (NotificationAdditions)

- (void) registerForNotification:(NSString *)notificaton selector:(SEL)selector
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:selector name:notificaton object:nil];
}

- (void) unregisterForNotification:(NSString *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notification object:nil];
}

- (void) unregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@implementation NSNotificationCenter (NotificationAdditions)

+ (void) postNotification:(NSString *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
}

+ (void) postNotificationToMainThread:(NSString *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
    });
}

+ (void) postNotification:(NSString *)notification withObject:(id)object
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object];
}

+ (void) postNotificationToMainThread:(NSString *)notification withObject:(id)object
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object];
    });
}

+ (void) postNotification:(NSString *)notification withObject:(id)object userInfo:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object userInfo:userInfo];
}

+ (void) postNotificationToMainThread:(NSString *)notification withObject:(id)object userInfo:(NSDictionary *)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object userInfo:userInfo];
    });
}

+ (void) postNotification:(NSString *)notification userInfo:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil userInfo:userInfo];
}

+ (void) postNotificationToMainThread:(NSString *)notification userInfo:(NSDictionary *)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil userInfo:userInfo];
    });
}

+ (void) notifyOnceForNotification:(NSString *)notificationName usingBlock:(void (^)(NSNotification *note))block
{
    if (!block) {
        return;
    }
    
    __block id observer;
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer name:notificationName object:nil];
        block(note);
    }];
}

@end
