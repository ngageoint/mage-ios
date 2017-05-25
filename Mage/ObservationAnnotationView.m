//
//  ObservationAnnotationView.m
//  MAGE
//
//  Created by William Newman on 1/19/16.
//

#import "ObservationAnnotationView.h"

@interface ObservationAnnotationView ()

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) NSObject<AnnotationDragCallback> *dragCallback;

@end

@implementation ObservationAnnotationView

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
            imageFrame.origin.y = imageFrame.origin.y - weakSelf.image.size.height;
            [weakSelf setFrame:imageFrame];
         }
         completion:^(BOOL finished) {
             weakSelf.dragState = MKAnnotationViewDragStateDragging;
         }];
    
    } else if (newDragState == MKAnnotationViewDragStateEnding) {
        __weak __typeof__(self) weakSelf = self;
        [UIView animateWithDuration:.2 animations:^{
            CGRect imageFrame = weakSelf.frame;
            imageFrame.origin.y = (imageFrame.origin.y - (weakSelf.image.size.height / 2));
            [weakSelf setFrame:imageFrame];
         }
         completion:^(BOOL finished) {
             [UIView animateWithDuration:.2 animations:^{
                 CGRect imageFrame = weakSelf.frame;
                 imageFrame.origin.y = imageFrame.origin.y + (weakSelf.image.size.height / 2);
                 [weakSelf setFrame:imageFrame];
              }
              completion:^(BOOL finished) {
                  weakSelf.dragState = MKAnnotationViewDragStateNone;
              }];
         }];
    } else if (newDragState == MKAnnotationViewDragStateCanceling) {
        [UIView animateWithDuration:0.2 animations:^{
            CGRect imageFrame = self.frame;
            imageFrame.origin.y = imageFrame.origin.y + self.image.size.height;
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
        CGPoint point = CGPointMake(center.x, center.y - self.centerOffset.y);
        CLLocationCoordinate2D coordinate = [_mapView convertPoint:point toCoordinateFromView:self.superview];
        [self.dragCallback draggingAnnotationView:self atCoordinate:coordinate];
    }
}

@end
