//
//  ObservationViewController.m
//  MAGE
//
//  Created by William Newman on 11/2/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationViewController.h"
#import "Server.h"
#import "Event.h"
#import "User.h"
#import "Role.h"
#import "ObservationDataStore.h"
#import "ObservationFields.h"
#import "ObservationFavorite.h"
#import "ObservationImportant.h"
#import "ObservationPropertyTableViewCell.h"
#import "ObservationEditViewController.h"
#import "UserTableViewController.h"
#import "MapDelegate.h"
#import "AttachmentViewController.h"
#import "GeometryUtility.h"
#import "ObservationPushService.h"
#import "ObservationEditCoordinator.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ObservationViewController ()<NSFetchedResultsControllerDelegate, ObservationPushDelegate, ObservationEditDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (nonatomic, assign) BOOL manualSync;

@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) NSMutableArray *formFields;
@property (strong, nonatomic) NSString *variantField;
@property (nonatomic, strong) NSFetchedResultsController *favoritesFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *importantFetchedResultsController;
@property (nonatomic, strong) NSArray *forms;
@property (nonatomic, strong) NSArray *observationForms;
@property (nonatomic, strong) NSMutableArray *childCoordinators;
@end

@implementation ObservationViewController

static NSInteger const NUMBER_OF_SECTIONS = 5;
static NSInteger const STATUS_SECTION = 0;
static NSInteger const SYNC_SECTION = 1;
static NSInteger const HEADER_SECTION = 2;
static NSInteger const ATTACHMENT_SECTION = 3;
static NSInteger const IMPORTANT_SECTION = 4;

- (void) editComplete: (Observation *) observation {
    self.observation = [observation MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    [self setupObservation];
}

- (void) observationDeleted:(Observation *)observation {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        [self.navigationItem setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeAlways];
    } else {
        // Fallback on earlier versions
    }
    
    [self registerCellTypes];
    
    self.childCoordinators = [[NSMutableArray alloc] init];

    self.currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    self.forms = [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].forms;
    
    [self.propertyTable setEstimatedRowHeight:44.0f];
    [self.propertyTable setRowHeight:UITableViewAutomaticDimension];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUserDefaults:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void) registerCellTypes {
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationActionsTableViewCell" bundle:nil] forCellReuseIdentifier:@"actions"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationFavoritesTableViewCell" bundle:nil] forCellReuseIdentifier:@"favorites"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationImportantTableViewCell" bundle:nil] forCellReuseIdentifier:@"updateImportant"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationAddImportantTableViewCell" bundle:nil] forCellReuseIdentifier:@"addImportant"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationMapTableViewCell" bundle:nil] forCellReuseIdentifier:@"map"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationCheckboxViewTableViewCell" bundle:nil] forCellReuseIdentifier:@"checkbox"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationPasswordTableViewCell" bundle:nil] forCellReuseIdentifier:@"password"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationStatusErrorTableViewCell" bundle:nil] forCellReuseIdentifier:@"statusError"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationStatusNeedsSyncTableViewCell" bundle:nil] forCellReuseIdentifier:@"statusNeedsSync"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationStatusSyncingTableViewCell" bundle:nil] forCellReuseIdentifier:@"statusSyncing"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationStatusOkTableViewCell" bundle:nil] forCellReuseIdentifier:@"statusOk"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationSyncTableViewCell" bundle:nil] forCellReuseIdentifier:@"syncObservation"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationSyncingTableViewCell" bundle:nil] forCellReuseIdentifier:@"syncingObservation"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationAttachmentTableViewCell" bundle:nil] forCellReuseIdentifier:@"attachments"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationPropertyTableViewCell" bundle:nil] forCellReuseIdentifier:@"property"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationGeometryTableViewCell" bundle:nil] forCellReuseIdentifier:@"geometry"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationDateTableViewCell" bundle:nil] forCellReuseIdentifier:@"date"];
    [self.propertyTable registerNib:[UINib nibWithNibName:@"ObservationMultiSelectTableViewCell" bundle:nil] forCellReuseIdentifier:@"multiselectdropdown"];
}


- (void) setupObservation {
    self.observationForms = [self.observation.properties objectForKey:@"forms"];
    
    self.manualSync = NO;
    self.tableLayout = [[NSMutableArray alloc] initWithCapacity:NUMBER_OF_SECTIONS];
    
    self.favoritesFetchedResultsController = [ObservationFavorite MR_fetchAllSortedBy:@"observation.timestamp"
                                                                            ascending:NO
                                                                        withPredicate:[NSPredicate predicateWithFormat:@"observation == %@", self.observation]
                                                                              groupBy:nil
                                                                             delegate:self
                                                                            inContext:[NSManagedObjectContext MR_defaultContext]];
    
    self.importantFetchedResultsController = [ObservationImportant MR_fetchAllSortedBy:@"observation.timestamp"
                                                                             ascending:NO
                                                                         withPredicate:[NSPredicate predicateWithFormat:@"observation == %@", self.observation]
                                                                               groupBy:nil
                                                                              delegate:self
                                                                             inContext:[NSManagedObjectContext MR_defaultContext]];
    
    [self setupEditButton];
    [self setupNonPropertySections];
    
    NSString *primaryText = [self.observation primaryFieldText];
    if (primaryText != nil && [primaryText length] > 0) {
        self.navigationItem.title = primaryText;
    }
    
    [self.propertyTable reloadData];
}

- (void) updateUserDefaults: (NSNotification *) notification {
    [self.propertyTable reloadData];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupObservation];
    [[ObservationPushService singleton] addObservationPushDelegate:self];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.favoritesFetchedResultsController.delegate = nil;
    self.favoritesFetchedResultsController = nil;

    self.importantFetchedResultsController.delegate = nil;
    self.importantFetchedResultsController = nil;

    [[ObservationPushService singleton] removeObservationPushDelegate:self];
}

- (void) setupNonPropertySections {
    if (self.observation.isDirty) {
        if ([self.observation hasValidationError]) {
            [self.tableLayout insertObject:@[@"statusError"] atIndex:STATUS_SECTION];
        } else {
            [self.tableLayout insertObject:@[@"statusNeedsSync"] atIndex:STATUS_SECTION];
        }
    } else {
        [self.tableLayout insertObject:@[@"statusOk"] atIndex:STATUS_SECTION];
    }
    
    [self.tableLayout insertObject:@[] atIndex:SYNC_SECTION];
    [self.tableLayout insertObject:[self getHeaderSection] atIndex:HEADER_SECTION];
    [self.tableLayout insertObject:[self getAttachmentsSection] atIndex:ATTACHMENT_SECTION];
    
    if ([self canEditObservationImportant] && !self.observation.isImportant) {
        [self.tableLayout insertObject:@[@"addImportant"] atIndex:IMPORTANT_SECTION];
    } else if (self.observation.isImportant) {
        [self.tableLayout insertObject:@[@"updateImportant"] atIndex:IMPORTANT_SECTION];
    }

}

- (void) setupEditButton {
    User *user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    if ([self userHasEditPermissions:user]) {
        self.editButton.style = UIBarButtonItemStylePlain;
        self.editButton.enabled = YES;
        self.editButton.title = @"Edit";
    } else {
        self.editButton.style = UIBarButtonItemStylePlain;
        self.editButton.enabled = NO;
        self.editButton.title = nil;
    }
}

- (NSMutableArray *) getHeaderSection {
    return [[NSMutableArray alloc] init];
}

- (NSMutableArray *) getAttachmentsSection {
    return [[NSMutableArray alloc] init];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return self.tableLayout.count + [self.formFields count];
}


- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    if (section < self.tableLayout.count) {
        return [self.tableLayout[section] count];
    } else {
        return [[self.formFields objectAtIndex:(section - self.tableLayout.count)] count];
    }
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ObservationPropertyTableViewCell *observationCell = (ObservationPropertyTableViewCell *) cell;
    
    NSDictionary *field = [[self.formFields objectAtIndex:([indexPath section] - self.tableLayout.count)] objectAtIndex:[indexPath row]];
    id title = [field objectForKey:@"title"];
    id value = [[self.observationForms objectAtIndex:([indexPath section] - self.tableLayout.count)] objectForKey:[field objectForKey:@"name"]];

    [observationCell populateCellWithKey:title andValue:value];
}

- (NSString *) cellIdentifierForType: (NSString *) type {
    if ([type isEqualToString:@"checkbox"] || [type isEqualToString:@"password"] || [type isEqualToString:@"geometry"] || [type isEqualToString:@"date"] || [type isEqualToString:@"multiselectdropdown"]) {
        return type;
    }
    return @"property";
}

- (ObservationPropertyTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    NSDictionary *field = [[self.formFields objectAtIndex:([indexPath section] - self.tableLayout.count)] objectAtIndex:[indexPath row]];

    ObservationPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self cellIdentifierForType:[field objectForKey:@"type"]]];
    cell.fieldDefinition = field;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section < self.tableLayout.count) {
        id cell = [tableView dequeueReusableCellWithIdentifier:self.tableLayout[indexPath.section][indexPath.row]];

        if ([cell respondsToSelector:@selector(configureCellForObservation:withForms:)]) {
            [cell configureCellForObservation:self.observation withForms:self.forms];
        }

        if ([cell respondsToSelector:@selector(setAttachmentSelectionDelegate:)]) {
            [cell setAttachmentSelectionDelegate:self];
        }

        if ([cell respondsToSelector:@selector(setObservationImportantDelegate:)]) {
            [cell setObservationImportantDelegate:self];
        }
        
        if ([cell respondsToSelector:@selector(setObservationActionsDelegate:)]) {
            [cell setObservationActionsDelegate:self];
        }

        return cell;
    } else {
        ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
        [self configureCell:cell atIndexPath:indexPath];
        [cell.valueTextView.textContainer setLineBreakMode:NSLineBreakByWordWrapping];

        cell.separatorInset = UIEdgeInsetsMake(0.f, cell.bounds.size.width, 0.f, 0.f);

        return cell;
    }
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    BOOL isSyncSectionShowing = [[self.tableLayout objectAtIndex:SYNC_SECTION] containsObject:@"syncObservation"];
    if (!isSyncSectionShowing && indexPath.section == STATUS_SECTION && [[self.tableLayout objectAtIndex:STATUS_SECTION] containsObject:@"statusNeedsSync"]) {
        [self.tableLayout replaceObjectAtIndex:SYNC_SECTION withObject:@[@"syncObservation"]];

        [tableView cellForRowAtIndexPath:indexPath].selectionStyle = UITableViewCellSelectionStyleNone;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:SYNC_SECTION] withRowAnimation:UITableViewRowAnimationTop];
    } else if (isSyncSectionShowing && indexPath.section == SYNC_SECTION && !self.manualSync) {
        self.manualSync = YES;
        [self.tableLayout replaceObjectAtIndex:STATUS_SECTION withObject:@[@"statusSyncing"]];
        [self.tableLayout replaceObjectAtIndex:SYNC_SECTION withObject:@[@"syncingObservation"]];

        [tableView reloadSections:[NSIndexSet indexSetWithIndex:STATUS_SECTION] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:SYNC_SECTION] withRowAnimation:UITableViewRowAnimationNone];

        [[ObservationPushService singleton] pushObservations:@[self.observation]];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger) section {
    NSString *title = nil;

    BOOL isSyncSectionShowing = [[self.tableLayout objectAtIndex:SYNC_SECTION] count];
    if (isSyncSectionShowing && section == SYNC_SECTION) {
        title = @"Manually push";
    } else if (section >= self.tableLayout.count) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.id = %@", [[self.observationForms objectAtIndex:(section - self.tableLayout.count)] objectForKey:@"formId"]];
        NSArray *filteredArray = [self.forms filteredArrayUsingPredicate:predicate];
        
        title = [[filteredArray firstObject] objectForKey:@"name"];
    }

    return title;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *title = nil;

    BOOL isSyncSectionShowing = [[self.tableLayout objectAtIndex:SYNC_SECTION] count];
    if (isSyncSectionShowing && section == SYNC_SECTION) {
        title = @"MAGE will automatically send your changes to the server, you can also manually attempt to send your changes now.";
    }

    return title;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == STATUS_SECTION) {
        return CGFLOAT_MIN;
    }

    if (section < [self.tableLayout count] && ![[self.tableLayout objectAtIndex:section] count]) {
        return CGFLOAT_MIN;
    }

    return UITableViewAutomaticDimension;
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    BOOL isSyncSectionShowing = [[self.tableLayout objectAtIndex:SYNC_SECTION] count];
    if (isSyncSectionShowing && section == SYNC_SECTION) {
        return UITableViewAutomaticDimension;
    }

    return CGFLOAT_MIN;
}

- (IBAction)editObservationTapped:(id)sender {
    ObservationEditCoordinator *edit  = [[ObservationEditCoordinator alloc] initWithRootViewController:self andDelegate:self andObservation:self.observation andLocation:nil];

    [self.childCoordinators addObject:edit];
    [edit start];

}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"clicked attachment %@", attachment.url);
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[self.observation.properties valueForKey:@"type"] style: UIBarButtonItemStylePlain target:nil action:nil];

    if ([segue.identifier isEqualToString:@"viewImageSegue"]) {
        AttachmentViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    } else if ([segue.identifier isEqualToString:@"FavoriteUsersSegue"]) {
        NSMutableArray *userIds = [[NSMutableArray alloc] init];
        [self.observation.favorites enumerateObjectsUsingBlock:^(ObservationFavorite * _Nonnull favorite, BOOL * _Nonnull stop) {
            [userIds addObject:favorite.userId];
        }];

        UserTableViewController *vc = [segue destinationViewController];
        vc.userIds = userIds;
    }
}

- (NSArray *) formFields {
    if (_formFields != nil) {
        return _formFields;
    }
    _formFields = [[NSMutableArray alloc] init];
    for (NSDictionary *form in [self.observation.properties objectForKey:@"forms"]) {
        
        NSPredicate *formPredicate = [NSPredicate predicateWithFormat:@"SELF.id = %@", [form objectForKey:@"formId"]];
        NSArray *filteredArray = [self.forms filteredArrayUsingPredicate:formPredicate];
        NSDictionary *eventForm = [filteredArray firstObject];
        
        NSMutableDictionary *propertiesWithValue = [form mutableCopy];
        NSMutableArray *keyWithNoValue = [[propertiesWithValue allKeysForObject:@""] mutableCopy];
        [keyWithNoValue addObjectsFromArray:[propertiesWithValue allKeysForObject:@[]]];
        [propertiesWithValue removeObjectsForKeys:keyWithNoValue];
        [propertiesWithValue removeObjectForKey:@"formId"];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived = %@ AND (SELF.name IN %@) AND type IN %@", nil, [propertiesWithValue allKeys], [ObservationFields fields]];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
        
        [_formFields addObject:[[[eventForm objectForKey:@"fields"] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]]];
    }
    return _formFields;
}


- (BOOL) userHasEditPermissions:(User *) user {
    return [user.role.permissions containsObject:@"UPDATE_OBSERVATION_ALL"] || [user.role.permissions containsObject:@"UPDATE_OBSERVATION_EVENT"];
}

- (BOOL) canEditObservationImportant {
    return self.currentUser && [self.currentUser.role.permissions containsObject:@"UPDATE_EVENT"];
}

- (IBAction) observationFavoriteTapped:(id)sender {
    [self.observation toggleFavoriteWithCompletion:nil];
}

- (void)observationDirectionsTapped:(id)sender {
    NSURL *appleMapsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.apple.com/?ll=%f,%f&q=%@", self.observation.location.coordinate.latitude, self.observation.location.coordinate.longitude, [self.observation primaryFieldText]]];
    NSURL *googleMapsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/maps/dir/?api=1&destination=%f,%f", self.observation.location.coordinate.latitude, self.observation.location.coordinate.longitude]];
    
    NSMutableDictionary *urlMap = [[NSMutableDictionary alloc] init];
    [urlMap setObject:appleMapsUrl forKey:@"Apple Maps"];
    
    if ([[UIApplication sharedApplication] canOpenURL:googleMapsUrl]) {
        [urlMap setObject:googleMapsUrl forKey:@"Google Maps"];
    }
    if ([urlMap count] > 0) {
        [self presentMapsActionSheetForURLs:urlMap];
    } else {
        [[UIApplication sharedApplication] openURL:appleMapsUrl options:@{} completionHandler:^(BOOL success) {
            NSLog(@"opened? %d", success);
        }];
    }
}

- (void) presentMapsActionSheetForURLs: (NSDictionary *) urlMap {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Get Directions With..."
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (NSString *app in urlMap) {
        [alert addAction:[UIAlertAction actionWithTitle:app style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[urlMap valueForKey:app] options:@{} completionHandler:^(BOOL success) {
                NSLog(@"opened? %d", success);
            }];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = self.view.frame;
        alert.popoverPresentationController.permittedArrowDirections = 0;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentActivityController:(UIActivityViewController *)controller {
    // for iPad: make the presentation a Popover
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    
    UIPopoverPresentationController *popController = [controller popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.barButtonItem = self.navigationItem.leftBarButtonItem;
    
    // access the completion handler
    controller.completionWithItemsHandler = ^(NSString *activityType,
                                              BOOL completed,
                                              NSArray *returnedItems,
                                              NSError *error){
        // react to the completion
        if (completed) {
            // user shared an item
            NSLog(@"We used activity type%@", activityType);
        } else {
            // user cancelled
            NSLog(@"We didn't want to share anything after all.");
        }
        
        if (error) {
            NSLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
        }
    };
}

- (void) updateFavorites {

}

-(IBAction) observationShareTapped:(id)sender {
    [self.observation shareObservationForViewController:self];
}

- (void) removeObservationImportant {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Remove Important Flag"
                                                                              message:@"Are you sure you want to remove this observations important flag?"
                                                                       preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Remove Flag" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.observation removeImportantWithCompletion:nil];
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];

}

- (void) flagObservationImportant {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil
                                                                              message:@"Description (optional)"
                                                                       preferredStyle:UIAlertControllerStyleAlert];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"description";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleNone;
        textField.backgroundColor = [UIColor clearColor];

        ObservationImportant *important = self.observation.observationImportant;
        if (important && [important.important isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            textField.text = important.reason;
        }
    }];

    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField *textField = textfields[0];

        [self.observation flagImportantWithDescription:textField.text completion:nil];
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void) updateImportant {
    BOOL isImportant = [self.observation isImportant];
    NSArray *importantSection = [self.tableLayout objectAtIndex:IMPORTANT_SECTION];
    if (!isImportant && [self canEditObservationImportant]) {
        if (![importantSection containsObject:@"addImportant"]) {
            [self.tableLayout replaceObjectAtIndex:IMPORTANT_SECTION withObject:@[@"addImportant"]];
            [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:IMPORTANT_SECTION] withRowAnimation:UITableViewRowAnimationFade];
        }
    } else if (isImportant) {
        if (![importantSection containsObject:@"updateImportant"]) {
            [self.tableLayout replaceObjectAtIndex:IMPORTANT_SECTION withObject:@[@"updateImportant"]];
            [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:IMPORTANT_SECTION] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [UIView performWithoutAnimation:^{
                [self.propertyTable reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:IMPORTANT_SECTION]] withRowAnimation:UITableViewRowAnimationNone];
            }];
        }
    } else if (!isImportant) {
        if ([importantSection count] > 0) {
            [self.tableLayout replaceObjectAtIndex:IMPORTANT_SECTION withObject:@[]];
            [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:IMPORTANT_SECTION] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
    [[NSManagedObjectContext MR_defaultContext] refreshObject:self.observation mergeChanges:YES];

    if ([anObject isKindOfClass:[ObservationFavorite class]]) {
        [self updateFavorites];
    } else if ([anObject isKindOfClass:[ObservationImportant class]]) {
        [self updateImportant];
    }
}

- (void) didPushObservation:(Observation *) observation success:(BOOL) success error:(NSError *) error {
    if (![observation.objectID isEqual:self.observation.objectID]) {
        return;
    }

    if (![observation isDirty] && observation.error == nil) {
        [self.tableLayout replaceObjectAtIndex:SYNC_SECTION withObject:@[]];
        [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:SYNC_SECTION] withRowAnimation:UITableViewRowAnimationFade];

        [self.tableLayout replaceObjectAtIndex:STATUS_SECTION withObject:@[@"statusOk"]];
        [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:STATUS_SECTION] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        if ([self.observation hasValidationError]) {
            [self.tableLayout replaceObjectAtIndex:STATUS_SECTION withObject:@[@"statusError"]];

            [self.tableLayout replaceObjectAtIndex:SYNC_SECTION withObject:@[]];
            [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:SYNC_SECTION] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.tableLayout replaceObjectAtIndex:STATUS_SECTION withObject:@[@"statusNeedsSync"]];
        }

        [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:STATUS_SECTION] withRowAnimation:UITableViewRowAnimationFade];

        if (self.manualSync) {
            self.manualSync = NO;

            if ([[self.tableLayout objectAtIndex:SYNC_SECTION] containsObject:@"syncingObservation"]) {
                [self.tableLayout replaceObjectAtIndex:SYNC_SECTION withObject:@[@"syncObservation"]];
                [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:SYNC_SECTION] withRowAnimation:UITableViewRowAnimationFade];
            }

            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Observation Not Synced"
                                                                           message:[observation errorMessage]
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

@end
