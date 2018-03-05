//
//  Theme+UIResponder.m
//  MAGE
//
//  Created by Dan Barela on 3/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "Theme+UIResponder.h"

@import ObjectiveC;

@interface ThemeNotifier : NSObject
@property (nonatomic, copy) void (^block)(NSNotification *notification);
@end

@implementation ThemeNotifier

- (instancetype)initWithName:(NSString *)name object:(id)object block:(void(^)(NSNotification *notification))block {
    NSParameterAssert(name);
    NSParameterAssert(block);
    
    if (self = [super init]) {
        self.block = block;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(notificationReceived:)
                                                     name:name
                                                   object:object];
    }
    return self;
}

- (void)notificationReceived:(NSNotification *)notification {
    self.block(notification);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

#pragma mark - Category

@interface UIResponder (Theme_Private)

@property (nonatomic, strong) ThemeNotifier *themeChangedNotifier;

@end

@implementation UIResponder (Theme)

- (void)registerForThemeChanges {
    NSAssert([self respondsToSelector:@selector(themeDidChange:)], @"%@ must implement %@", NSStringFromClass(self.class), NSStringFromSelector(@selector(themeDidChange:)));
    
    __weak typeof(self) weakSelf = self;
    self.themeChangedNotifier = [[ThemeNotifier alloc] initWithName:kThemeChangedKey object:nil block:^(NSNotification *notification) {
        
        [weakSelf themeDidChange:TheCurrentTheme];
    }];
    
    [self themeDidChange:TheCurrentTheme];
}

- (ThemeNotifier *)themeChangedNotifier {
    return objc_getAssociatedObject(self, @selector(themeChangedNotifier));
}

- (void)setThemeChangedNotifier:(ThemeNotifier *)themeChangedNotifier {
    objc_setAssociatedObject(self, @selector(themeChangedNotifier), themeChangedNotifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
