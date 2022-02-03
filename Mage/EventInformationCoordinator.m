//
//  EventInformationCoordinator.m
//  MAGE
//
//  Created by William Newman on 1/29/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventInformationCoordinator.h"
#import "MAGE-Swift.h"

@interface EventInformationCoordinator()<UINavigationControllerDelegate, FormDefaultsDelegate>

@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (weak, nonatomic) UINavigationController *viewController;
@property (strong, nonatomic) EventInformationController *eventInfomationController;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation EventInformationCoordinator

- (instancetype) initWithViewController: (UINavigationController *) viewController event:(Event *) event scheme: (id<MDCContainerScheming>) containerScheme {
    if (self = [super init]) {
        self.scheme = containerScheme;
        self.childCoordinators = [[NSMutableArray alloc] init];
        self.viewController = viewController;
        self.viewController.delegate = self;
        self.eventInfomationController = [[EventInformationController alloc] initWithScheme: self.scheme];
        self.eventInfomationController.event = event;
    }
    return self;
}

-(void) start {
    self.eventInfomationController.delegate = self;
    self.eventInfomationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.viewController pushViewController:self.eventInfomationController animated:true];
}

- (void) startIpad {
    self.eventInfomationController.delegate = self;
    self.eventInfomationController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.viewController showDetailViewController:self.eventInfomationController sender:self];
}

- (void)formSelected:(nonnull Form *)form {
    FormDefaultsCoordinator* coordinator = [[FormDefaultsCoordinator alloc] initWithNavController:self.eventInfomationController.navigationController event:self.eventInfomationController.event form:form scheme: self.scheme delegate:self];
    [self.childCoordinators addObject:coordinator];
    [coordinator start];
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

- (void) formDefaultsCompleteWithCoordinator:(NSObject *)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

@end
