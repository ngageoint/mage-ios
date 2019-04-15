//
//  StaticPointAnnotation.m
//  MAGE
//
//

#import "StaticPointAnnotation.h"

@implementation StaticPointAnnotation

-(id) initWithFeature:(NSDictionary *)feature {
    if ((self = [super init])) {
        _feature = feature;
        // Set a title so that the annotation tap event will actually occur on the map delegate
        self.title = @" ";
        NSArray *coordinates = [_feature valueForKeyPath:@"geometry.coordinates"];
        [self setCoordinate:CLLocationCoordinate2DMake([[coordinates objectAtIndex: 1] floatValue], [[coordinates objectAtIndex: 0] floatValue])];
        _iconUrl = [_feature valueForKeyPath:@"properties.style.iconStyle.icon.href"];
    }
    return self;
}

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView {
    if (self.iconUrl == nil) {
        return [self defaultAnnotationView:mapView];
    } else {
        return [self customAnnotationView:mapView];
    }
}

- (MKAnnotationView *) defaultAnnotationView: (MKMapView *) mapView {
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"pinAnnotation"];
    if (annotationView == nil) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"pinAnnotation"];
    } else {
        annotationView.annotation = self;
    }
    
    return annotationView;
}

- (MKAnnotationView *) customAnnotationView: (MKMapView *) mapView {
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:_iconUrl];
    
    if (annotationView == nil) {
        NSLog(@"showing icon from %@", self.iconUrl);
        
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:self.iconUrl];
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        UIImage *image = nil;
        if ([[self.iconUrl lowercaseString] hasPrefix:@"http"]) {
            image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.iconUrl]]];
        } else {
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
            image = [UIImage imageWithData:[NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsDirectory,self.iconUrl]]];
        }
        
        CGFloat scale = image.size.width / 35.0;
        annotationView.image = [UIImage imageWithCGImage:[image CGImage] scale:scale orientation:image.imageOrientation];
        
        annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f));
        annotationView.annotation = self;
    } else {
        annotationView.annotation = self;
    }
    
    return annotationView;
}

- (UIView *) detailViewForAnnotation {
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = false;
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:300]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:200]];
    
    NSString *description = [_feature valueForKeyPath: @"properties.description"];
    
    NSMutableAttributedString *attributedDescription = [[NSMutableAttributedString alloc] initWithData:[description dataUsingEncoding:NSUTF8StringEncoding]
                                                                                 options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                           NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                      documentAttributes:nil error:nil];
    NSString *titleText = [_feature valueForKeyPath: @"properties.name"];
    self.title = nil;
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = titleText;
    titleLabel.font = [UIFont systemFontOfSize:20];
    titleLabel.translatesAutoresizingMaskIntoConstraints = false;
    titleLabel.numberOfLines = 1;
    [view addSubview:titleLabel];

    UILabel *descriptionLabel = [[UILabel alloc] init];
    descriptionLabel.attributedText = attributedDescription;
    descriptionLabel.font = [UIFont systemFontOfSize:12];
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false;
    descriptionLabel.numberOfLines = 0;
    
    CGFloat labelHeight = [self getLabelHeight:descriptionLabel];
    
    [descriptionLabel addConstraint:[NSLayoutConstraint constraintWithItem:descriptionLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:labelHeight]];
    [descriptionLabel addConstraint:[NSLayoutConstraint constraintWithItem:descriptionLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:200]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:labelHeight]];
    
    [view addSubview:descriptionLabel];

    NSDictionary *views = NSDictionaryOfVariableBindings(titleLabel, descriptionLabel);

    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[titleLabel]|" options:0 metrics:nil views:views]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:descriptionLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:descriptionLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1 constant:titleText == nil ? 0 :30]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[titleLabel]-[descriptionLabel]|" options:0 metrics:nil views:views]];

    return view;
}

- (CGFloat)getLabelHeight:(UILabel*)label
{
    CGSize constraint = CGSizeMake(label.frame.size.width, CGFLOAT_MAX);
    CGSize size;
    
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [label.attributedText boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin context:context].size;
    
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    
    return size.height;
}

@end
