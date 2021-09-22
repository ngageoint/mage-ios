//
//  EmailBuilder.m
//  MAGE
//
//  Created by Kevin Gilland on 9/15/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EmailBuilder.h"

@implementation EmailBuilder

-(instancetype) initWithMessage: (NSString *)message andIdentifier: (NSString *)identifier andStrategy: (NSString *)strategy {
    self = [super init];
    if (self != nil) {
        [self setMessage:message];
        [self setIdentifier:identifier];
        [self setStrategy:strategy];
        [self setSubject:@""];
        [self setBody:@""];
    }
    return self;
}

-(void) build {
    NSString * upperMessage = [_message uppercaseString];
    
    if ([upperMessage containsString:@"DEVICE"]) {
        if ([upperMessage containsString:@"REGISTER"]) {
            _subject = [_subject stringByAppendingString:@"Please approve my device"];
        } else {
            _subject = [_subject stringByAppendingString:@"Device ID issue"];
        }
    } else {
        if ([upperMessage containsString:@"APPROVED"] || [upperMessage containsString:@"ACTIVATE"]) {
            _subject = [_subject stringByAppendingString:@"Please activate my account"];
        } else if ([upperMessage containsString:@"DISABLED"]) {
            _subject = [_subject stringByAppendingString:@"Please enable my account"];
        } else if ([upperMessage containsString:@"LOCKED"]) {
            _subject = [_subject stringByAppendingString:@"Please unlock my account"];
        } else {
            _subject = [_subject stringByAppendingString:@"User login issue"];
        }
    }
    
    if (_identifier != nil) {
        _subject = [_subject stringByAppendingString:@" - "];
        _subject = [_subject stringByAppendingString:_identifier];
        _body = [_body stringByAppendingString:@"Identifier (username or device id): "];
        _body = [_body stringByAppendingString:_identifier];
        _body = [_body stringByAppendingString:@"\n"];
    }
    if (_strategy != nil) {
        _body = [_body stringByAppendingString:@"Authentication Method: "];
        _body = [_body stringByAppendingString:_strategy];
        _body = [_body stringByAppendingString:@"\n"];
    }
    
    _body = [_body stringByAppendingString:@"Error Message Received: "];
    _body = [_body stringByAppendingString:_message];
    
}

@end
