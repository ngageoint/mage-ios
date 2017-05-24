//
//  MapShapePointAnnotationView.m
//  MAGE
//
//  Created by Brian Osborn on 5/24/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapShapePointAnnotationView.h"

@implementation MapShapePointAnnotationView

static float popUpHeightPercentage = 1.5;

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

@end
