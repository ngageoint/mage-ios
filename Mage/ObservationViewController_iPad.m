//
//  ObservationViewController_iPad.m
//  MAGE
//
//

#import "ObservationViewController_iPad.h"
#import <Server+helper.h>
#import <GeoPoint.h>
#import <Event+helper.h>

@implementation ObservationViewController_iPad

-(void)viewDidLoad {
    [super viewDidLoad];
    NSString *name = [self.observation.properties valueForKey:@"type"];
    if (name != nil) {
        self.primaryFieldLabel.text = name;
    } else {
        self.primaryFieldLabel.text = @"Observation";
    }
    
    
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = event.form;
    NSString *variantField = [form objectForKey:@"variantField"];
    NSString *variantText = [self.observation.properties objectForKey:variantField];
    if (variantField != nil && variantText != nil && [variantText isKindOfClass:[NSString class]] && variantText.length > 0) {
        self.secondaryFieldLabel.text = [self.observation.properties objectForKey:variantField];
    } else {
        [self.secondaryFieldLabel removeFromSuperview];
    }
}

- (IBAction)getDirections:(id)sender {
    CLLocationCoordinate2D coordinate = ((GeoPoint *) self.observation.geometry).location.coordinate;
    NSURL *testURL = [NSURL URLWithString:@"comgooglemaps-x-callback://"];
    if ([[UIApplication sharedApplication] canOpenURL:testURL]) {
        NSString *directionsRequest = [NSString stringWithFormat:@"%@://?daddr=%f,%f&x-success=%@&x-source=%s",
                                       @"comgooglemaps-x-callback",
                                       coordinate.latitude,
                                       coordinate.longitude,
                                       @"mage://?resume=true",
                                       "MAGE"];
        NSURL *directionsURL = [NSURL URLWithString:directionsRequest];
        [[UIApplication sharedApplication] openURL:directionsURL];
    } else {
        NSLog(@"Can't use comgooglemaps-x-callback:// on this device.");
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:[self.observation.properties valueForKey:@"type"]];
        NSDictionary *options = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
        [mapItem openInMapsWithLaunchOptions:options];
    }
}

@end
