//
//  FetchServicesHolder.h
//  MAGE
//
//  Created by Dan Barela on 9/23/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LocationFetchService.h>
#import <ObservationFetchService.h>
#import <ObservationPushService.h>
#import <AttachmentPushService.h>

@interface FetchServicesHolder : NSObject

@property (weak, nonatomic) LocationFetchService *locationFetchService;
@property (weak, nonatomic) ObservationFetchService *observationFetchService;
@property (weak, nonatomic) ObservationPushService *observationPushService;
@property (weak, nonatomic) AttachmentPushService *attachmentPushService;

@end
