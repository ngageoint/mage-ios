//
//  ContactInfo.m
//  MAGE
//
//  Created by Kevin Gilland on 9/22/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ContactInfo.h"
#import "DeviceUUID.h"
#import "LinkGenerator.h"

@implementation ContactInfo

- (instancetype) initWithTitle: (NSString *)title andMessage: (NSString *) message {
    
    self = [super init];
    if (!self) return nil;
    
    [self setTitle:title];
    [self setMessage:message];
    
    return self;
}

- (NSAttributedString *) messageWithContactInfo {
    NSString * htmlString = [self constructMessage];
       NSAttributedString *attributedString = [[NSAttributedString alloc]
                 initWithData: [htmlString dataUsingEncoding:NSUnicodeStringEncoding]
                      options: @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
           documentAttributes: nil
                        error: nil
       ];
    return attributedString;
}

- (NSString *) constructMessage {
    if(_identifier == nil) {
        NSUUID * uuid = [DeviceUUID retrieveDeviceUUID];
        _identifier = [uuid UUIDString];
    }
    
    NSString* emailLink = [LinkGenerator emailLinkWithMessage:_message andIdentifier:_identifier andStrategy:_strategy];
    NSString* phoneLink = [LinkGenerator phoneLink];
    
    NSString* extendedMessage = [_message copy];
    if(emailLink != nil || phoneLink != nil) {
        extendedMessage = [extendedMessage stringByAppendingString:@"<br /><br />"];
        extendedMessage = [extendedMessage stringByAppendingString:@"You may contact your MAGE administrator via "];
        
        if (emailLink != nil && [emailLink length] > 0) {
            extendedMessage = [extendedMessage stringByAppendingString:@"<a href="];
            extendedMessage = [extendedMessage stringByAppendingString:emailLink];
            extendedMessage = [extendedMessage stringByAppendingString:@">Email</a>"];
        }
        if ((emailLink != nil && [emailLink length] > 0) && (phoneLink != nil && [phoneLink length] > 0)) {
            extendedMessage = [extendedMessage stringByAppendingString:@" or "];
        }
        if (phoneLink != nil && [phoneLink length] > 0) {
            extendedMessage = [extendedMessage stringByAppendingString:@"<a href="];
            extendedMessage = [extendedMessage stringByAppendingString:phoneLink];
            extendedMessage = [extendedMessage stringByAppendingString:@">Phone</a>"];
        }
        extendedMessage = [extendedMessage stringByAppendingString:@" for further assistance."];
    }
    
    return extendedMessage;
}

@end
