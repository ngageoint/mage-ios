//
//  EmailBuilder.m
//  MAGE
//
//  Created by Kevin Gilland on 9/15/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EmailBuilder.h"

@implementation EmailBuilder

-(instancetype) initWithMessage: (NSString *)message andUsername: (NSString *)username andStrategy: (NSString *)strategy {
    self = [super init];
    if (self != nil) {
        [self setMessage:message];
        [self setUsername:username];
        [self setStrategy:strategy];
        [self setSubject:@""];
        [self setBody:@""];
    }
    return self;
}

-(void) build {
    if ([_message rangeOfString:@"device" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        if ([_message rangeOfString:@"register" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            _subject = [_subject stringByAppendingString:@"Please Approve My MAGE Device"];
        } else {
            _subject = [_subject stringByAppendingString:@"Device ID issue"];
        }
    } else {
        if (([_message rangeOfString:@"approved" options:NSCaseInsensitiveSearch].location != NSNotFound) || ([_message rangeOfString:@"activate" options:NSCaseInsensitiveSearch].location != NSNotFound)) {
            _subject = [_subject stringByAppendingString:@"Please Activate My MAGE Account"];
        } else if ([_message rangeOfString:@"disabled" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            _subject = [_subject stringByAppendingString:@"Please Enable My MAGE Account"];
        } else if ([_message rangeOfString:@"locked" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            _subject = [_subject stringByAppendingString:@"Please Unlock My MAGE Account"];
        } else {
            _subject = [_subject stringByAppendingString:@"User Sign-In Issue"];
        }
    }
    
    if (_username != nil) {
        _body = [_body stringByAppendingString:@"Username: "];
        _body = [_body stringByAppendingString:_username];
        _body = [_body stringByAppendingString:@"\n\n"];
    }
    if (_strategy != nil) {
        _body = [_body stringByAppendingString:@"Authentication Method: "];
        _body = [_body stringByAppendingString:_strategy];
        _body = [_body stringByAppendingString:@"\n"];
    }
    
    _body = [_body stringByAppendingString:@"Message: "];
    _body = [_body stringByAppendingString:_message];
    
}

@end
