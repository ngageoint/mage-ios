//
//  PersonViewController.m
//  Mage
//
//  Created by Billy Newman on 7/17/14.
//

#import "PersonViewController.h"
#import "LocationAnnotation.h"
#import "User+helper.h"
#import "PersonImage.h"
#import "GeoPoint.h"
#import "NSDate+DateTools.h"
#import "ObservationTableViewCell.h"
#import "ObservationViewController.h"
#import "Observations.h"

@interface PersonViewController()
	@property (nonatomic, strong) NSDateFormatter *dateFormatter;
	@property (nonatomic, strong) NSString *variantField;
    @property (nonatomic) NSDateFormatter *sectionDateFormatter;
    @property (nonatomic) NSDateFormatter *dateFormatterToDate;
@end

@implementation PersonViewController

- (NSDateFormatter *) sectionDateFormatter {
    if (_sectionDateFormatter == nil) {
        _sectionDateFormatter = [[NSDateFormatter alloc] init];
        _sectionDateFormatter.dateStyle = kCFDateFormatterLongStyle;
        _sectionDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        
    }
    
    return _sectionDateFormatter;
}

- (NSDateFormatter *) dateFormatterToDate {
    if (_dateFormatterToDate == nil) {
        _dateFormatterToDate = [[NSDateFormatter alloc] init];
        _dateFormatterToDate.dateFormat = @"yyyy-MM-dd";
        _dateFormatterToDate.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }
    
    return _dateFormatterToDate;
}

- (NSDateFormatter *) dateFormatter {
	if (_dateFormatter == nil) {
		_dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
		[_dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
	}
	
	return _dateFormatter;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    Locations *locations = [Locations locationsForUser:self.user inManagedObjectContext:self.contextHolder.managedObjectContext];
    [self.mapDelegate setLocations:locations];
    
    Observations *observations = [Observations observationsForUser:self.user inManagedObjectContext:self.contextHolder.managedObjectContext];
    [self.observationDataStore startFetchControllerWithObservations:observations];
	
	CLLocationCoordinate2D coordinate = [self.user.location location].coordinate;
	
	_name.text = [NSString stringWithFormat:@"%@ (%@)", _user.name, _user.username];
	_timestamp.text = [self.dateFormatter stringFromDate:_user.location.timestamp];
	
	_latLng.text = [NSString stringWithFormat:@"%.6f, %.6f", coordinate.latitude, coordinate.longitude];
	
	if (_user.email.length != 0 && _user.phone.length != 0) {
		_contact1.text = _user.email;
		_contact2.text = _user.phone;
	} else if (_user.email.length != 0) {
		_contact1.text = _user.email;
	} else if (_user.phone.length != 0) {
		_contact1.text = _user.phone;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *form = [defaults objectForKey:@"form"];
    _variantField = [form objectForKey:@"variantField"];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
    
    CLLocationDistance latitudeMeters = 500;
    CLLocationDistance longitudeMeters = 500;
    NSDictionary *properties = _user.location.properties;
    id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
    if (accuracyProperty != nil) {
        double accuracy = [accuracyProperty doubleValue];
        latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
        longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
    }
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([self.user.location location].coordinate, latitudeMeters, longitudeMeters);
    MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
    
    [self.mapDelegate selectedUser:self.user region:viewRegion];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	CAGradientLayer *maskLayer = [CAGradientLayer layer];
    
    //this is the anchor point for our gradient, in our case top left. setting it in the middle (.5, .5) will produce a radial gradient. our startPoint and endPoints are based off the anchorPoint
    maskLayer.anchorPoint = CGPointZero;
    
    // Setting our colors - since this is a mask the color itself is irrelevant - all that matters is the alpha.
	// A clear color will completely hide the layer we're masking, an alpha of 1.0 will completely show the masked view.
    UIColor *outerColor = [UIColor colorWithWhite:1.0 alpha:.25];
    UIColor *innerColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    
    // An array of colors that dictatates the gradient(s)
    maskLayer.colors = @[(id)outerColor.CGColor, (id)outerColor.CGColor, (id)innerColor.CGColor, (id)innerColor.CGColor];
    
    // These are percentage points along the line defined by our startPoint and endPoint and correspond to our colors array.
	// The gradient will shift between the colors between these percentage points.
    maskLayer.locations = @[@0.0, @0.0, @0.35, @0.35f];
    maskLayer.bounds = _mapView.frame;
	UIView *view = [[UIView alloc] initWithFrame:_mapView.frame];
    
    view.backgroundColor = [UIColor blackColor];
    
    [self.view insertSubview:view belowSubview:self.mapView];
    self.mapView.layer.mask = maskLayer;
}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([[segue identifier] isEqualToString:@"DisplayObservationSegue"]) {
        id destination = [segue destinationViewController];
        NSIndexPath *indexPath = [_observationTableView indexPathForCell:sender];
		Observation *observation = [self.observationDataStore.observations.fetchedResultsController objectAtIndexPath:indexPath];
		[destination setObservation:observation];
        [self.observationTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
