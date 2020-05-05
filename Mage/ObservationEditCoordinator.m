//
//  ObservationEditCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditCoordinator.h"
#import "Event.h"
#import "User.h"
#import "Attachment.h"
#import "ObservationPropertiesEditCoordinator.h"
#import "FormDefaults.h"
#import "MAGE-Swift.h"

@interface ObservationEditCoordinator() <ObservationPropertiesEditDelegate>

@property (strong, nonatomic) UIViewController *rootViewController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Event *event;
@property (nonatomic) BOOL newObservation;
@property (strong, nonatomic) id<ObservationEditDelegate> delegate;
@property (strong, nonatomic) FormPickerViewController *formController;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) Observation *observation;
@property (strong, nonatomic) SFGeometry *location;
@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (strong, nonatomic) NSDictionary *currentEditField;
@property (strong, nonatomic) id currentEditValue;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (nonatomic) CLLocationAccuracy accuracy;
@property (strong, nonatomic) NSString *provider;
@property (nonatomic) double delta;
@property (strong, nonatomic) ObservationPropertiesEditCoordinator *propertiesEditCoordinator;

@end

@implementation ObservationEditCoordinator

- (instancetype) initWithRootViewController: (UIViewController *) rootViewController andDelegate: (id<ObservationEditDelegate>) delegate andLocation: (SFGeometry *) location andAccuracy: (CLLocationAccuracy) accuracy andProvider: (NSString *) provider andDelta: (double) delta {
    self = [super init];
    if (!self) return nil;
    
    self.managedObjectContext = [NSManagedObjectContext MR_newMainQueueContext];
    self.managedObjectContext.parentContext = [NSManagedObjectContext MR_rootSavingContext];
    [self.managedObjectContext MR_setWorkingName:@"Observation New Context"];
    self.managedObjectContext.stalenessInterval = 0.0;
    
    self.newObservation = YES;
    self.observation = [self createObservationAtLocation:location withAccuracy:accuracy andProvider:provider andDelta:delta];
    
    [self setupCoordinatorWithRootViewController:rootViewController andDelegate:delegate];
    
    return self;
}

- (instancetype) initWithRootViewController:(UIViewController *)rootViewController andDelegate:(id<ObservationEditDelegate>)delegate andObservation:(Observation *)observation {
    self = [super init];
    if (!self) return nil;
    
    self.managedObjectContext = [NSManagedObjectContext MR_newMainQueueContext];
    self.managedObjectContext.parentContext = [NSManagedObjectContext MR_rootSavingContext];
    [self.managedObjectContext MR_setWorkingName:@"Observation Edit Context"];
    self.managedObjectContext.stalenessInterval = 0.0;
    
    self.observation = [self setupObservation: observation];
    [self setupCoordinatorWithRootViewController:rootViewController andDelegate:delegate];
    
    return self;
}

- (void) setupCoordinatorWithRootViewController: (UIViewController *) rootViewController andDelegate: (id<ObservationEditDelegate>) delegate {
    self.rootViewController = rootViewController;
    [self pushViewController:rootViewController];
    self.delegate = delegate;
    self.location = [self.observation getGeometry];
    self.childCoordinators = [[NSMutableArray alloc] init];
    self.navigationController = [[UINavigationController alloc] init];
}

- (Observation *) createObservationAtLocation: (SFGeometry *) location withAccuracy: (CLLocationAccuracy) accuracy andProvider: (NSString *) provider andDelta: (double) delta {
    self.newObservation = YES;
    Observation *observation = [Observation observationWithGeometry:location andAccuracy: accuracy andProvider: provider andDelta: delta inManagedObjectContext:self.managedObjectContext];
    observation.dirty = [NSNumber numberWithBool:YES];
    return observation;
}

- (Observation *) setupObservation: (Observation *) observation {
    Observation *observationInContext = [observation MR_inContext:self.managedObjectContext];
    observationInContext.dirty = [NSNumber numberWithBool:YES];
    return observationInContext;
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

- (Event *) event {
    if (_event) return _event;
    _event = [Event getCurrentEventInContext:self.managedObjectContext];
    return _event;
}

- (void) start {
    if (![self.event isUserInEvent:[User fetchCurrentUserInManagedObjectContext:self.managedObjectContext]]) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"You are not part of this event"
                                     message:@"You cannot create observations for an event you are not part of."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self.rootViewController presentViewController:alert animated:YES completion:nil];
    } else {
        [self.navigationController setModalPresentationStyle:UIModalPresentationCustom];
        [self.navigationController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        [self.rootViewController presentViewController:self.navigationController animated:YES completion:^{

        }];
        [self startEditObservationFields];
        if (self.newObservation) {
            if ([self.event.nonArchivedForms count] > 1) {
                [self startFormPicker];
            } else if ([self.event.nonArchivedForms count] == 1) {
                [self addFormToObservation:[self.event.nonArchivedForms objectAtIndex:0]];
            }
        }
    }
}

- (void) addForm {
    [self startFormPicker];
}

- (void) startFormPicker {
    self.formController = [[FormPickerViewController alloc] initWithDelegate:self andForms:self.event.nonArchivedForms];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.formController];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelSelection)];
    [[self.formController navigationItem] setLeftBarButtonItem:backBarButtonItem];
    [[self navigationController] presentViewController:nav animated:true completion:nil];
}

- (void) startEditObservationFields {
    self.propertiesEditCoordinator = [[ObservationPropertiesEditCoordinator alloc] initWithObservation: self.observation andNewObservation: self.newObservation andNavigationController: self.navigationController andDelegate:self];
    [_childCoordinators addObject:self.propertiesEditCoordinator];
    [self.propertiesEditCoordinator start];
}

- (void) addFormToObservation: (NSDictionary *) form {
    NSMutableDictionary *newProperties = [self.observation.properties mutableCopy];
    
    NSMutableArray *observationForms = [[newProperties objectForKey:@"forms"] mutableCopy];
    NSMutableDictionary *newForm = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[form objectForKey:@"id"], @"formId", nil];
    
    FormDefaults *defaults = [[FormDefaults alloc] initWithEventId:[self.observation.eventId integerValue] formId:[[form objectForKey:@"id"] integerValue]];
    NSDictionary *formDefaults = [defaults getDefaultsMap];
    
    NSArray *fields = [form objectForKey:@"fields"];
    if (formDefaults.count > 0) { // user defaults
        for (NSDictionary *field in fields) {
            id value = nil;
            id defaultField = [formDefaults objectForKey:[field objectForKey:@"id"]];
            if (defaultField) {
                value = [defaultField objectForKey:@"value"];
            }
            
            if (value) {
                [newForm setObject:value forKey:[field objectForKey:@"name"]];
            }
        }
    } else { // server defaults
        for (NSDictionary *field in fields) {
            // grab the server default from the form fields value property
            id value = [field objectForKey:@"value"];
            
            if (value) {
                [newForm setObject:value forKey:[field objectForKey:@"name"]];
            }
        }
    }
    
    [observationForms addObject:newForm];
    
    [newProperties setObject:observationForms forKey:@"forms"];
    self.observation.properties = newProperties;
    [self.propertiesEditCoordinator formAdded];
}

#pragma mark - FormPickedDelegate methods
- (void) formPicked:(NSDictionary *)form {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Form Picked %@", [form objectForKey:@"name"]);
    [self addFormToObservation:form];
//    [self startEditObservationFields];
}

- (void) cancelSelection {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        NSLog(@"root view dismissed");
    }];
}

#pragma

#pragma mark - ObservationPropertiesEditDelegate methods

- (void) deleteObservation {
    [self.observation deleteObservationWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
        NSLog(@"Deleted");
    }];
    [self propertiesEditCanceled];
    [self.delegate observationDeleted:self.observation coordinator:self];
}

- (void) propertiesEditCanceled {
    self.managedObjectContext = nil;
    [self.delegate editCancel:self];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
        
        [weakSelf.delegate editComplete:weakSelf.observation coordinator:self];
        
        [_rootViewController dismissViewControllerAnimated:YES completion:^{
            NSLog(@"root view dismissed");
            weakSelf.managedObjectContext = nil;
        }];
    }];
}

#pragma


@end
