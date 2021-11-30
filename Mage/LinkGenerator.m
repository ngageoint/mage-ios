//
//  LinkGenerator.m
//  MAGE
//
//  Created by Kevin Gilland on 9/15/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LinkGenerator.h"
#import "EmailBuilder.h"

@implementation LinkGenerator

+(NSString *) emailLinkWithMessage: (NSString *)message andIdentifier: (NSString *)ident andStrategy: (NSString *) strategy {
    NSString * url;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * email = [defaults valueForKeyPath:@"contactInfoEmail"];
    
    if(email != nil && [email length] > 0) {
        EmailBuilder * builder = [[EmailBuilder alloc] initWithMessage:message
                                                         andIdentifier:ident
                                                           andStrategy:strategy];
        [builder build];
        NSString * encodedTo = [email stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        NSString * encodedSubject = [builder.subject stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        NSString * encodedBody = [builder.body stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];

        url = @"";
        url = [@"mailto:" stringByAppendingString:encodedTo];
        url = [url stringByAppendingString:@"?subject="];
        url = [url stringByAppendingString:encodedSubject];
        url = [url stringByAppendingString:@"&body="];
        url = [url stringByAppendingString:encodedBody];
    }
    
    return url;
}

+(NSString *) phoneLink {
    NSString * url;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * phone = [defaults valueForKeyPath:@"contactInfoPhone"];
    
    if(phone != nil && [phone length] > 0) {
        NSString * encodedPhone = [phone stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        url = @"";
        url = [@"tel:" stringByAppendingString:encodedPhone];
    }
    
    return url;
}

@end
