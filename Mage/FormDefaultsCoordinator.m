//
//  FormDefaultsCoordinator.m
//  MAGE
//
//  Created by William Newman on 1/30/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FormDefaultsCoordinator.h"
#import "FormDefaultsTableViewController.h"
#import "SelectEditViewController.h"
#import "GeometryEditCoordinator.h"
#import "GeometryEditViewController.h"
#import "GeometrySerializer.h"
#import "GeometryDeserializer.h"
#import "FormDefaults.h"

@interface FormDefaultsCoordinator()<FormDefaultsControllerDelegate, PropertyEditDelegate, GeometryEditDelegate>

@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (weak, nonatomic) UINavigationController *viewController;
@property (strong, nonatomic) FormDefaultsTableViewController *formDefaultsController;
@property (strong, nonatomic) Event *event;
@property (strong, nonatomic) NSDictionary *form;
@property (strong, nonatomic) NSMutableDictionary *defaults;
@property (strong, nonatomic) NSMutableDictionary *selectedField;
@property (strong, nonatomic) id selectedValue;

@end

@implementation FormDefaultsCoordinator

- (instancetype) initWithViewController: (UINavigationController *) viewController event:(Event *) event form:(NSDictionary *) form {
    if (self = [super init]) {
        self.childCoordinators = [[NSMutableArray alloc] init];
        self.viewController = viewController;
        self.formDefaultsController = [[FormDefaultsTableViewController alloc] init];
        self.formDefaultsController.delegate = self;
        self.event = event;
        self.form = form;
        
        [self buildDefaults];
    }
    
    return self;
}

- (void) start {
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.formDefaultsController];
    [navigationController setModalPresentationStyle:UIModalPresentationCustom];
    [navigationController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(save)];
    self.formDefaultsController.navigationItem.leftBarButtonItem = cancelButton;
    self.formDefaultsController.navigationItem.rightBarButtonItem = saveButton;
    
    [self.viewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)save {
    FormDefaults *formDefaults = [[FormDefaults alloc] initWithEventId:[self.event.remoteId integerValue] formId:[[self.form objectForKey:@"id"] integerValue]];
    
    // Compare server defaults with self.defaults.  If they are the same clear the defaults
    if ([self.defaults isEqual:[self serverDefaults]]) {
        [formDefaults clearDefaults];
    } else {
        [formDefaults setDefaults:self.defaults];
    }
    
    [self.formDefaultsController.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.delegate formDefaultsComplete:self];
}

- (void)cancel {
    [self.formDefaultsController.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.delegate formDefaultsComplete:self];
}

- (void)reset {
    self.defaults = [self serverDefaults];
    self.formDefaultsController.form = self.defaults;
    [self.formDefaultsController.tableView reloadData];
}

- (void) buildDefaults {
    FormDefaults *formDefaults = [[FormDefaults alloc] initWithEventId:[self.event.remoteId integerValue] formId:[[self.form objectForKey:@"id"] integerValue]];
    NSMutableDictionary *defaults = [formDefaults getDefaults];
    
    if (defaults) {
        self.defaults = defaults;
    } else {
        self.defaults = [self serverDefaults];
    }
    
    self.formDefaultsController.form = self.defaults;
}

- (NSMutableDictionary *) serverDefaults {
    // Make a mutable copy of the original form
    NSMutableDictionary *defaults = [FormDefaults mutableForm:self.form];
    
    // filter out archived fields and sort
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived == %@ || archived == nil", @NO];
    NSArray *fields = [[defaults valueForKey:@"fields"] filteredArrayUsingPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    [defaults setObject:[fields sortedArrayUsingDescriptors:@[sortDescriptor]] forKey:@"fields"];
    
    return defaults;
}

- (void)fieldSelected:(nonnull NSMutableDictionary *)field {
    self.selectedField = field;
    self.selectedValue = [field objectForKey:@"value"];
    NSString *type = [field objectForKey:@"type"];
    if ([type isEqualToString:@"dropdown"] || [type isEqualToString:@"multiselectdropdown"] || [type isEqualToString:@"radio"]) {
        SelectEditViewController *editSelect = [[SelectEditViewController alloc] initWithFieldDefinition:field andValue:self.selectedValue andDelegate:self];
        editSelect.title = [field valueForKey:@"title"];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(selectFieldEditCanceled)];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(selectFieldEditDone)];
        [editSelect.navigationItem setLeftBarButtonItem:backButton];
        [editSelect.navigationItem setRightBarButtonItem:doneButton];
        [self.formDefaultsController.navigationController pushViewController:editSelect animated:YES];
    } else if ([type isEqualToString:@"geometry"]) {
        GeometryEditCoordinator *editCoordinator = [[GeometryEditCoordinator alloc] initWithFieldDefinition:field andGeometry:self.selectedValue andPinImage:nil andDelegate:self andNavigationController:self.formDefaultsController.navigationController];
        [self.childCoordinators addObject:editCoordinator];
        [editCoordinator start];
    }
}

- (void) fieldEditDone:(NSMutableDictionary *)field value:(nonnull id)value reload:(BOOL) reload {
    [self saveField:field value:value reload:reload];
}

- (void)setValue:(id)value forFieldDefinition:(NSDictionary *)fieldDefinition {
    NSLog(@"value forFieldDefinition");
    self.selectedValue = value;
}

- (void)invalidValue:(id)value forFieldDefinition:(NSDictionary *)fieldDefinition {
    NSLog(@"invalidValue forFieldDefinition");
}

- (void) selectFieldEditDone {
    [self saveField:self.selectedField value:self.selectedValue reload:YES];
    [self.formDefaultsController.navigationController popViewControllerAnimated:YES];
}

- (void) selectFieldEditCanceled {
    self.selectedField = nil;
    self.selectedValue = nil;
    [self.formDefaultsController.navigationController popViewControllerAnimated:YES];
}

- (void) geometryEditComplete:(SFGeometry *)geometry coordinator:(id)coordinator {
    [self saveField:self.selectedField value:geometry reload:YES];
    [self.formDefaultsController.navigationController popViewControllerAnimated:YES];
    [self.childCoordinators removeObject:coordinator];
}

- (void) geometryEditCancel:(id)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

- (void) saveField:(NSMutableDictionary *) field value:(id) value reload:(BOOL) reload {
    if (value == nil) {
        [field removeObjectForKey:@"value"];
    } else {
        [field setObject:value forKey:@"value"];
    }

    if (reload) {
        [self.formDefaultsController.tableView reloadData];
    }
}

@end
