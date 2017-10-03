//
//  MapShapePointAnnotationView.m
//  MAGE
//
//  Created by Brian Osborn on 5/24/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapShapePointAnnotationView.h"

@interface MapShapePointAnnotationView ()

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) NSObject<AnnotationDragCallback> *dragCallback;

@end

@implementation MapShapePointAnnotationView

static float popUpHeightPercentage = 1.0;

- (instancetype)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier andMapView: (MKMapView *) mapView andDragCallback: (NSObject<AnnotationDragCallback> *) dragCallback{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if(self){
        self.mapView = mapView;
        self.dragCallback = dragCallback;
    }
    return self;
}

- (void)setDragState:(MKAnnotationViewDragState)newDragState animated:(BOOL)animated {
    [super setDragState:newDragState animated:animated];
    
    if (newDragState == MKAnnotationViewDragStateStarting) {
        __weak __typeof__(self) weakSelf = self;
        [UIView animateWithDuration:0.3 animations:^{
            CGRect imageFrame = weakSelf.frame;
            imageFrame.origin.y = imageFrame.origin.y - popUpHeightPercentage * weakSelf.image.size.height;
            [weakSelf setFrame:imageFrame];
        }
                         completion:^(BOOL finished) {
                             weakSelf.dragState = MKAnnotationViewDragStateDragging;
                         }];
        
    } else if (newDragState == MKAnnotationViewDragStateEnding) {
        __weak __typeof__(self) weakSelf = self;
        [UIView animateWithDuration:.2 animations:^{
            CGRect imageFrame = weakSelf.frame;
            [weakSelf setFrame:imageFrame];
        }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:.2 animations:^{
                                 CGRect imageFrame = weakSelf.frame;
                                 [weakSelf setFrame:imageFrame];
                             }
                                              completion:^(BOOL finished) {
                                                  weakSelf.dragState = MKAnnotationViewDragStateNone;
                                              }];
                         }];
    } else if (newDragState == MKAnnotationViewDragStateCanceling) {
        [UIView animateWithDuration:0.2 animations:^{
            CGRect imageFrame = self.frame;
            imageFrame.origin.y = imageFrame.origin.y + popUpHeightPercentage * self.image.size.height;
            [self setFrame:imageFrame];
        }
                         completion:^(BOOL finished) {
                             self.dragState = MKAnnotationViewDragStateNone;
                         }];
    }
}

- (void) setCenter:(CGPoint)center{
    [super setCenter:center];
    if(self.dragCallback != nil){
        CLLocationCoordinate2D coordinate = [_mapView convertPoint:center toCoordinateFromView:self.superview];
        [self.dragCallback draggingAnnotationView:self atCoordinate:coordinate];
    }
}

@end
