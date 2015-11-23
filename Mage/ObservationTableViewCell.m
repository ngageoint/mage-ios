//
//  ObservationTableViewCell.m
//  Mage
//
//

#import "ObservationTableViewCell.h"
#import "ObservationImage.h"
#import <NSDate+DateTools.h>
#import <User.h>
#import <Server+helper.h>
#import "AttachmentCollectionDataStore.h"
#import <Event+helper.h>
#import "NSDate+iso8601.h"

@interface ObservationTableViewCell()

@property (strong, nonatomic) AttachmentCollectionDataStore *ads;

@end

@implementation ObservationTableViewCell

- (void) populateCellWithObservation:(Observation *) observation {
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = event.form;
    NSString *variantField = [form objectForKey:@"variantField"];
    NSString *type = [observation.properties objectForKey:@"type"];
    self.primaryField.text = type;
    NSString *variantText = [observation.properties objectForKey:variantField];
    if (variantField != nil && variantText != nil && [variantText isKindOfClass:[NSString class]] && [variantText length] > 0) {
        self.variantField.text = variantText;
    } else {
        self.variantField.text = nil;
    }
    
    self.icon.image = [ObservationImage imageForObservation:observation scaledToWidth:[NSNumber numberWithFloat:35]];
    
    self.timeField.text = observation.timestamp.shortTimeAgoSinceNow;
    
    self.userField.text = observation.user.name;
    
    self.ads = [[AttachmentCollectionDataStore alloc] init];
    self.ads.attachmentCollection = self.attachmentCollection;
    self.attachmentCollection.delegate = self.ads;
    self.attachmentCollection.dataSource = self.ads;
    self.ads.observation = observation;
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
}

@end
