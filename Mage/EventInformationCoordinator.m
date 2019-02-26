//
//  EventInformationCoordinator.m
//  MAGE
//
//  Created by William Newman on 1/29/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventInformationCoordinator.h"
#import "FormDefaultsCoordinator.h"

@interface EventInformationCoordinator()<UINavigationControllerDelegate, FormDefaultsDelegate>

@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (weak, nonatomic) UINavigationController *viewController;
@property (strong, nonatomic) EventInformationController *eventInfomationController;

@end

@implementation EventInformationCoordinator

- (instancetype) initWithViewController: (UINavigationController *) viewController event:(Event *) event {
    if (self = [super init]) {
        self.childCoordinators = [[NSMutableArray alloc] init];
        self.viewController = viewController;
        self.viewController.delegate = self;
        self.eventInfomationController = [[EventInformationController alloc] init];
        self.eventInfomationController.delegate = self;
        self.eventInfomationController.event = event;
    }
    return self;
}

-(void) start {
    [self.viewController showDetailViewController:self.eventInfomationController sender:self];
}

- (void)formSelected:(nonnull NSDictionary *)form {
    FormDefaultsCoordinator* coordinator = [[FormDefaultsCoordinator alloc] initWithViewController:self.viewController event:self.eventInfomationController.event form:form];
    [self.childCoordinators addObject:coordinator];
    coordinator.delegate = self;
    [coordinator start];
    // TODO add delegate so I know when finished.
}

# pragma mark - UINavigationController Delegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    // ensure view controller is popping
    UIViewController *fromViewController = [self.viewController.transitionCoordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
    if ([self.viewController.viewControllers containsObject:fromViewController]) {
        return;
    }
    
    // check that popping view controller is the right type
    if ([fromViewController isKindOfClass:[EventInformationController class]]) {
        [self.delegate eventInformationComplete:self];
    }
}

# pragma mark - FormDefaultsCoordinator Delegate

- (void) formDefaultsComplete:(id)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

@end
