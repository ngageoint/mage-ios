//
//  FeatureDetailCoordinator.m
//  MAGE
//
//  Created by William Newman on 1/17/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FeatureDetailCoordinator.h"
#import "FeatureDetailViewController.h"

@interface FeatureDetailCoordinator () <UIPopoverPresentationControllerDelegate, FeatureDetailControllerDelegate>
@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) FeatureDetailViewController *detailController;
@property (strong, nonatomic) UIView *maskView;
@end

@implementation FeatureDetailCoordinator

- (instancetype) initWithViewController: (UIViewController *) viewController detail:(NSAttributedString *) detail {
    if (self = [super init]) {
        _viewController = viewController;
    
        _detailController = [[FeatureDetailViewController alloc] init];
        _detailController.delegate = self;
        _detailController.detail = detail;
        _detailController.modalPresentationStyle = UIModalPresentationPopover;
        _detailController.popoverPresentationController.delegate = self;
        _detailController.popoverPresentationController.backgroundColor = [UIColor clearColor];
        _detailController.popoverPresentationController.sourceView = viewController.view;
        _detailController.popoverPresentationController.sourceRect = CGRectMake(viewController.view.bounds.size.width / 2, viewController.view.bounds.size.height / 2, 1, 1);
        _detailController.popoverPresentationController.permittedArrowDirections = 0;
    }
    
    return self;
}

- (void) start {
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    self.maskView = [[UIView alloc] initWithFrame:window.bounds];
    self.maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.maskView.backgroundColor = [UIColor blackColor];
    self.maskView.alpha = 0;
    [window addSubview:self.maskView];
    
    [UIView animateWithDuration:.2 animations:^{
        self.maskView.alpha = .5;
    }];
    

    [self.viewController presentViewController:self.detailController animated:YES completion:nil];
}

#pragma mark - Feature Detail Controller Delegate

-(void) onDismiss {
    [self.detailController dismissViewControllerAnimated:YES completion:nil];
    
    if (self.maskView) {
        [UIView animateWithDuration:.2 animations:^{
            self.maskView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.maskView removeFromSuperview];
            self.maskView = nil;
        }];
    }
    
    if (self.delegate) {
        [self.delegate featureDetailComplete:self];
    }
}

#pragma mark - Popover Presentation Controller Delegate

- (BOOL) popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return NO;
}

- (void) popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing  _Nonnull *)view {
    *rect = CGRectMake(self.viewController.view.bounds.size.width / 2, self.viewController.view.bounds.size.height / 2, 1, 1);
}

#pragma mark - Adaptive Presentation Controller Delegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    // This method is called in iOS 8.3 or later regardless of trait collection, in which case use the original presentation style (UIModalPresentationNone signals no adaptation)
    return UIModalPresentationNone;
}

@end
