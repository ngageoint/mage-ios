//
//  ObservationAnnotationView.m
//  MAGE
//
//  Created by William Newman on 1/19/16.
//

#import "ObservationAnnotationView.h"

@implementation ObservationAnnotationView

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

@end
