//
//  ObservationTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 7/17/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationTableViewCell.h"
#import "ObservationImage.h"
#import <NSDate+DateTools.h>
#import <User.h>
#import <Server+helper.h>
#import "AttachmentCollectionDataStore.h"

@interface ObservationTableViewCell()

@property (strong, nonatomic) AttachmentCollectionDataStore *ads;

@end

@implementation ObservationTableViewCell

- (void) populateCellWithObservation:(Observation *) observation {
    
    NSDictionary *form = [Server observationForm];
    NSString *variantField = [form objectForKey:@"variantField"];
    NSString *type = [observation.properties objectForKey:@"type"];
    self.primaryField.text = type;
    if (variantField != nil) {
        self.variantField.text = [observation.properties objectForKey:variantField];
    }
    self.icon.image = [ObservationImage imageForObservation:observation scaledToWidth:[NSNumber numberWithFloat:35]];
    
    NSString *timestamp = [observation.properties objectForKey:@"timestamp"];
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    dateFormat.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    // Always use this locale when parsing fixed format date strings
    NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormat.locale = posix;
    NSDate* output = [dateFormat dateFromString:timestamp];
    
    self.timeField.text = output.shortTimeAgoSinceNow;
    
    self.userField.text = observation.user.name;
    
    self.ads = [[AttachmentCollectionDataStore alloc] init];
    self.ads.attachmentCollection = self.attachmentCollection;
    self.attachmentCollection.delegate = self.ads;
    self.attachmentCollection.dataSource = self.ads;
    self.ads.observation = observation;
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
}

@end
