//
//  FormPickerViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FormPickerViewController.h"
#import "FormCollectionViewCell.h"
#import <MapKit/MapKit.h>
#import "GeometryUtility.h"
#import "KTCenterFlowLayout.h"
#import "Theme+UIResponder.h"

@interface FormPickerViewController ()

@property (strong, nonatomic) id<FormPickedDelegate> delegate;
@property (strong, nonatomic) NSArray *forms;
@property (strong, nonatomic) WKBGeometry *location;
@property (nonatomic) BOOL newObservation;
@property (weak, nonatomic) IBOutlet UIView *blurView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation FormPickerViewController

static NSString *CellIdentifier = @"FormCell";

- (void) themeDidChange:(MageTheme)theme {
    self.blurView.backgroundColor = [[UIColor background] colorWithAlphaComponent:.6];
    self.closeButton.backgroundColor = [UIColor dialog];
    self.closeButton.layer.sublayers = nil;
    [self.closeButton.layer addSublayer:[self createInnerLineWithColor:[UIColor brand]]];
    
    [UIColor themeMap:self.mapView];
    self.headerLabel.textColor = [UIColor brand];
}

- (instancetype) initWithDelegate: (id<FormPickedDelegate>) delegate andForms: (NSArray *) forms andLocation: (WKBGeometry *) location andNewObservation: (BOOL) newObservation {
    self = [super init];
    if (!self) return nil;
    
    _delegate = delegate;
    _forms = forms;
    _location = location;
    _newObservation = newObservation;
    
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self drawCloseButton];
    [self setupMapBackground];
    
    [self registerForThemeChanges];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.newObservation) {
        _headerLabel.text = @"What type of observation would you like to create?";
    } else {
        _headerLabel.text = @"What type of form would you like to add to this observation?";
    }
    [self setupCollectionView];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void) drawCloseButton {
    self.closeButton.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    
    self.closeButton.layer.cornerRadius = self.closeButton.frame.size.width / 2;
    self.closeButton.layer.borderWidth = 1;
    self.closeButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
}

- (CALayer *) createInnerLineWithColor: (UIColor *) color {
    CALayer *borderLayer = [[CALayer alloc] init];
    borderLayer.frame = CGRectMake(3, 3, 44, 44);
    borderLayer.backgroundColor = [UIColor clearColor].CGColor;
    borderLayer.cornerRadius = borderLayer.frame.size.width / 2;
    borderLayer.borderColor = color.CGColor;
    borderLayer.borderWidth = 1.5;
    
    [self makeLineLayer:borderLayer lineFromPointA:CGPointMake(15, 15) toPointB:CGPointMake(29, 29) withColor:color];
    [self makeLineLayer:borderLayer lineFromPointA:CGPointMake(15, 29) toPointB:CGPointMake(29, 15) withColor:color];
    
    return borderLayer;
}

-(void) makeLineLayer: (CALayer *) layer lineFromPointA: (CGPoint) pointA toPointB: (CGPoint) pointB withColor: (UIColor *) color {
    CAShapeLayer *line = [CAShapeLayer layer];
    UIBezierPath *linePath=[UIBezierPath bezierPath];
    [linePath moveToPoint: pointA];
    [linePath addLineToPoint:pointB];
    line.path=linePath.CGPath;
    line.fillColor = nil;
    line.opacity = 1.0;
    line.lineWidth = 1.5;
    line.strokeColor = color.CGColor;
    [layer addSublayer:line];
}

- (void) setupCollectionView {
    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    [self.collectionView registerNib:[UINib nibWithNibName:@"FormCell" bundle:nil] forCellWithReuseIdentifier:CellIdentifier];
    
    KTCenterFlowLayout *layout = [KTCenterFlowLayout new];
    layout.minimumLineSpacing = 10.f;
    layout.minimumInteritemSpacing = 25.f;
    layout.estimatedItemSize = CGSizeMake(90.f, 120.f);
    
    [self.collectionView setCollectionViewLayout:layout];
}

- (void) setupMapBackground {
    if (self.location != nil) {
        WKBPoint *point = [GeometryUtility centroidOfGeometry:self.location];
        MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake([point.y doubleValue], [point.x doubleValue]), MKCoordinateSpanMake(.03125, .03125));
        MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
        [self.mapView setRegion:viewRegion animated:NO];
    }
    
    
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        self.blurView.backgroundColor = [UIColor clearColor];
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.blurView.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurEffectView.alpha = .95;
        
        [self.blurView addSubview:blurEffectView];
    } else {
        self.blurView.backgroundColor = [UIColor dialog];
    }
}

- (IBAction)closeButtonTapped:(id)sender {
    [self.delegate cancelSelection];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.forms count];
}

- (FormCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    FormCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell configureCellForForm:[self.forms objectAtIndex:[indexPath row]]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [_delegate formPicked: [self.forms objectAtIndex:[indexPath row]]];
}

@end
