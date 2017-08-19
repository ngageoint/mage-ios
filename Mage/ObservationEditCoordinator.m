//
//  ObservationEditCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditCoordinator.h"
#import <Event.h>
#import <User.h>
#import <Attachment.h>
#import "ObservationEditTableViewController.h"
#import "ObservationPropertiesEditCoordinator.h"

@interface ObservationEditCoordinator() <ObservationPropertiesEditDelegate>

@property (strong, nonatomic) UIViewController *rootViewController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Event *event;
@property (nonatomic) BOOL newObservation;
@property (strong, nonatomic) id<ObservationEditDelegate> delegate;
@property (strong, nonatomic) FormPickerViewController *formController;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) Observation *observation;
@property (strong, nonatomic) WKBGeometry *location;
@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (strong, nonatomic) NSDictionary *currentEditField;
@property (strong, nonatomic) id currentEditValue;
@property (strong, nonatomic) NSMutableArray *childCoordinators;

@end

@implementation ObservationEditCoordinator

- (instancetype) initWithRootViewController: (UIViewController *) rootViewController andDelegate: (id<ObservationEditDelegate>) delegate andObservation: (Observation *) observation andLocation: (WKBGeometry *) location {
    self = [super init];
    if (!self) return nil;
    
    _observation = observation;
    _location = location;
    _rootViewController = rootViewController;
    [self pushViewController:rootViewController];
    _delegate = delegate;
    
    _childCoordinators = [[NSMutableArray alloc] init];
    
    self.navigationController = [[UINavigationController alloc] init];
    
    [self setupObservation];
    
    return self;
}

- (NSMutableArray *) viewControllers {
    if (_viewControllers != nil) return _viewControllers;
    _viewControllers = [[NSMutableArray alloc] init];
    return _viewControllers;
}

- (UIViewController *) currentViewController {
    return [self.viewControllers lastObject];
}

- (void) popViewControllers {
    [self.viewControllers removeLastObject];
}

- (void) pushViewController: (UIViewController *) viewController {
    [self.viewControllers addObject:viewController];
}

- (NSManagedObjectContext *) managedObjectContext {
    if (_managedObjectContext) return _managedObjectContext;
    _managedObjectContext = [NSManagedObjectContext MR_newMainQueueContext];
    _managedObjectContext.parentContext = [NSManagedObjectContext MR_rootSavingContext];
    [_managedObjectContext MR_setWorkingName:@"Observation Edit Context"];
    return _managedObjectContext;
}

- (Event *) event {
    if (_event) return _event;
    _event = [Event getCurrentEventInContext:self.managedObjectContext];
    return _event;
}

- (void) setupObservation {
    // if self.observation is nil create a new one
    if (self.observation == nil) {
        self.newObservation = YES;
        self.observation = [Observation observationWithGeometry:self.location inManagedObjectContext:self.managedObjectContext];
    } else {
        self.observation = [self.observation MR_inContext:self.managedObjectContext];
    }
    
    self.observation.dirty = [NSNumber numberWithBool:YES];

}

- (void) start {
    [self.rootViewController presentViewController:self.navigationController animated:NO completion:^{
        
    }];
    if (![self.event isUserInEvent:[User fetchCurrentUserInManagedObjectContext:self.managedObjectContext]]) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"You are not part of this event"
                                     message:@"You cannot create observations for an event you are not part of."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self.rootViewController presentViewController:alert animated:YES completion:nil];
    } else {
        if (self.newObservation) {
            if ([self.event.forms count] > 1) {
                [self startFormPicker];
            } else if ([self.event.forms count] == 1) {
                [self addFormToObservation:[self.event.forms objectAtIndex:0]];
                [self startEditObservationFields];
            } else {
                [self startEditObservationFields];
            }
        } else {
            [self startEditObservationFields];
        }
    }
}

- (void) startFormPicker {
    self.formController = [[FormPickerViewController alloc] initWithDelegate:self andForms:self.event.forms andLocation: self.location andNewObservation:self.newObservation];
//    [self.currentViewController presentViewController:self.formController animated:YES completion:^{
//        NSLog(@"Form Picker shown");
//    }];
    [self.navigationController pushViewController:self.formController animated:NO];
//    [self pushViewController:self.formController];
}

- (void) startEditObservationFields {
    ObservationPropertiesEditCoordinator *propertiesEditCoordinator = [[ObservationPropertiesEditCoordinator alloc] initWithObservation: self.observation andNewObservation: self.newObservation andNavigationController: self.navigationController andDelegate:self];
    [_childCoordinators addObject:propertiesEditCoordinator];
    [propertiesEditCoordinator start];
}

- (void) addFormToObservation: (NSDictionary *) form {
    NSMutableDictionary *newProperties = [self.observation.properties mutableCopy];
    
    NSMutableArray *observationForms = [[newProperties objectForKey:@"forms"] mutableCopy];
    NSMutableDictionary *newForm = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[form objectForKey:@"id"], @"formId", nil];
    
    // fill in defaults
    NSArray *fields = [form objectForKey:@"fields"];
    for (NSDictionary *field in fields) {
        id value = [field objectForKey:@"value"];
        
        if (value) {
            [newForm setObject:value forKey:[field objectForKey:@"name"]];
        }
    }
    
    [observationForms addObject:newForm];
    
    [newProperties setObject:observationForms forKey:@"forms"];
    self.observation.properties = newProperties;
}

#pragma mark - FormPickedDelegate methods
- (void) formPicked:(NSDictionary *)form {
    [self.navigationController popViewControllerAnimated:NO];
    NSLog(@"Form Picked %@", [form objectForKey:@"name"]);
    [self addFormToObservation:form];
    [self startEditObservationFields];
}

#pragma

#pragma mark - ObservationPropertiesEditDelegate methods
- (void) propertiesEditCanceled {
    [self.navigationController dismissViewControllerAnimated:NO completion:^{
        NSLog(@"root view dismissed");
    }];
    
}

- (void) propertiesEditComplete {
    __weak typeof(self) weakSelf = self;
    
    self.observation.user = [User fetchCurrentUserInManagedObjectContext:self.managedObjectContext];
    
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (!contextDidSave) {
            NSLog(@"Error saving observation to persistent store, context did not save");
        }
        
        if (error) {
            NSLog(@"Error saving observation to persistent store %@", error);
        }
        
        NSLog(@"saved the observation: %@", weakSelf.observation.remoteId);
        
        [weakSelf.delegate editComplete:weakSelf.observation];
        
        [_rootViewController dismissViewControllerAnimated:NO completion:^{
            NSLog(@"root view dismissed");
        }];
    }];
}

#pragma


@end
