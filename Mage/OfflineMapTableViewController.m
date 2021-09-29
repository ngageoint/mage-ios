//
//  OfflineMapTableViewController.m
//  MAGE
//
//

#import "OfflineMapTableViewController.h"
#import <objc/runtime.h>
#import "CacheOverlays.h"
#import "MageConstants.h"
#import "CacheOverlayTableCell.h"
#import "ChildCacheOverlayTableCell.h"
#import "XYZDirectoryCacheOverlay.h"
#import "GeoPackageCacheOverlay.h"
#import "GPKGGeoPackageFactory.h"
#import "ObservationTableHeaderView.h"
#import "StaticLayer.h"
#import "Layer.h"
#import "Server.h"
#import "Event.h"
#import "MAGE-Swift.h"

@interface OfflineMapTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) CacheOverlays *cacheOverlays;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshLayersButton;
@property (nonatomic, strong) NSMutableSet *selectedStaticLayers;
@property (nonatomic, strong) NSFetchedResultsController *mapsFetchedResultsController;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation OfflineMapTableViewController

static const NSInteger DOWNLOADED_SECTION = 0;
static const NSInteger MY_MAPS_SECTION = 1;
static const NSInteger AVAILABLE_SECTION = 2;
static const NSInteger PROCESSING_SECTION = 3;

static NSString *DOWNLOADED_SECTION_NAME = @"%@ Layers";
static NSString *MY_MAPS_SECTION_NAME = @"My Layers";
static NSString *AVAILABLE_SECTION_NAME = @"Available Layers";
static NSString *PROCESSING_SECTION_NAME = @"Extracting Archives";

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.scheme = containerScheme;
    return self;
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    
    [self.tableView reloadData];
}


-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh Layers" style:UIBarButtonItemStylePlain target:self action:@selector(refreshLayers:)];
    
    self.mapsFetchedResultsController = [Layer MR_fetchAllGroupedBy:@"loaded" withPredicate:[NSPredicate predicateWithFormat:@"(eventId == %@ OR eventId == -1) AND (type == %@ OR type == %@ OR type == %@)", [Server currentEventId], @"GeoPackage", @"Local_XYZ", @"Feature"] sortedBy:@"loaded,name:YES" ascending:NO delegate:self];
    [self.mapsFetchedResultsController performFetch:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(geoPackageImported:) name: GeoPackageImported object:nil];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.selectedStaticLayers = [NSMutableSet setWithArray:[defaults valueForKeyPath:[NSString stringWithFormat: @"selectedStaticLayers.%@", [Server currentEventId]]]];
    
    self.cacheOverlays = [CacheOverlays getInstance];
    [self.cacheOverlays registerListener:self];
    
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void) geoPackageImported: (NSNotification *) notification {
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (IBAction)refreshLayers:(id)sender {
    self.refreshLayersButton.enabled = NO;
    [Layer refreshLayersForEvent:[Server currentEventId]];
}

-(void) cacheOverlaysUpdated: (NSArray<CacheOverlay *> *) cacheOverlays{
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (CacheOverlay *) findOverlayByRemoteId: (NSNumber *) remoteId {
    for(CacheOverlay * cacheOverlay in [self.cacheOverlays getOverlays]) {
        if ([cacheOverlay isKindOfClass:[GeoPackageCacheOverlay class]]) {
            GeoPackageCacheOverlay *gpCacheOverlay = (GeoPackageCacheOverlay *)cacheOverlay;
            NSString *filePath = gpCacheOverlay.filePath;
            // check if this filePath is consistent with a downloaded layer and if so, verify that layer is in this event
            NSArray *pathComponents = [filePath pathComponents];
            if ([[pathComponents objectAtIndex:[pathComponents count] - 3] isEqualToString:@"geopackages"]) {
                NSString *layerId = [pathComponents objectAtIndex:[pathComponents count] - 2];
                if ([layerId isEqualToString:[remoteId stringValue]]) {
                    return gpCacheOverlay;
                }
            }
        }
    }
    
    return nil;
}

- (Layer *) layerFromIndexPath: (NSIndexPath *) indexPath {
    return [self.mapsFetchedResultsController objectAtIndexPath:indexPath];
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{   NSLog(@"didChangeSection: called");
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    NSUInteger section = [self getSectionFromLayer:anObject];
    switch(type) {
    
       case NSFetchedResultsChangeInsert:
           [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                      withRowAnimation:UITableViewRowAnimationFade];
           break;

       case NSFetchedResultsChangeDelete:
           [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                      withRowAnimation:UITableViewRowAnimationFade];
           break;

       case NSFetchedResultsChangeUpdate:
           if (section == AVAILABLE_SECTION && indexPath.row == 0) {
               Layer *layer = (Layer *)anObject;
               UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
               if (layer.file) {
                   uint64_t downloadBytes = [layer.downloadedBytes longLongValue];
                              NSLog(@"Download bytes %ld", (long)downloadBytes);
                              cell.detailTextLabel.text = [NSString stringWithFormat:@"Downloading, Please wait: %@ of %@",
                                                           [NSByteCountFormatter stringFromByteCount:downloadBytes countStyle:NSByteCountFormatterCountStyleFile],
                                                           [NSByteCountFormatter stringFromByteCount:[[[layer file] valueForKey:@"size"] intValue] countStyle:NSByteCountFormatterCountStyleFile]];
               } else {
                   cell.detailTextLabel.text = [NSString stringWithFormat:@"Loading static feature data, Please wait"];
               }
           } else {
               [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
           }               break;

       case NSFetchedResultsChangeMove:
           [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                      withRowAnimation:UITableViewRowAnimationFade];
           [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                      withRowAnimation:UITableViewRowAnimationFade];
           break;
   }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [[self tableView] endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tableView {
    NSUInteger sectionCount = [self.mapsFetchedResultsController sections].count;
    
    if (sectionCount == 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width * .8, self.view.bounds.size.height)];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        imageView.image = [UIImage imageNamed:@"layers_large"];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.alpha = 0.6f;
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width * .8, 0)];
        title.text = @"No Layers";
        title.numberOfLines = 0;
        title.textAlignment = NSTextAlignmentCenter;
        title.translatesAutoresizingMaskIntoConstraints = NO;
        title.font = [UIFont systemFontOfSize:24];
        title.alpha = 0.6f;
        [title sizeToFit];
        
        UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width * .8, 0)];
        description.text = @"Event administrators can add layers to your event, or can be shared from other applications.";
        description.numberOfLines = 0;
        description.textAlignment = NSTextAlignmentCenter;
        description.translatesAutoresizingMaskIntoConstraints = NO;
        description.alpha = 0.6f;
        [description sizeToFit];
        
        [view addSubview:title];
        [view addSubview:description];
        [view addSubview:imageView];
        
        [title addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:self.view.bounds.size.width * .8]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];

        [description addConstraint:[NSLayoutConstraint constraintWithItem:description attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:self.view.bounds.size.width * .8]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:description attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        
        [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:100]];
        [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:100]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeBottom multiplier:1 constant:16]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:description attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:title attribute:NSLayoutAttributeBottom multiplier:1 constant:16]];
        
        self.tableView.backgroundView = view;
        return 0;
    }
    self.tableView.backgroundView = nil;
    
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.mapsFetchedResultsController.sections objectAtIndex:section] numberOfObjects];
}

- (NSInteger) getSectionFromLayer: (Layer *) layer {
    if (layer.loaded.floatValue == [NSNumber numberWithFloat:OFFLINE_LAYER_NOT_DOWNLOADED].floatValue || layer.loaded == nil) {
        return AVAILABLE_SECTION;
    } else if (layer.loaded.floatValue  == [NSNumber numberWithFloat:OFFLINE_LAYER_LOADED].floatValue ) {
        return DOWNLOADED_SECTION;
    } else if (layer.loaded.floatValue  == [NSNumber numberWithFloat:EXTERNAL_LAYER_LOADED].floatValue ) {
        return MY_MAPS_SECTION;
    } else {
        return PROCESSING_SECTION;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    Layer *layer = [[[self.mapsFetchedResultsController.sections objectAtIndex:section] objects] objectAtIndex:0];
    switch ([self getSectionFromLayer:layer]) {
        case AVAILABLE_SECTION:
            return AVAILABLE_SECTION_NAME;
        case DOWNLOADED_SECTION:
            return [NSString stringWithFormat:DOWNLOADED_SECTION_NAME, [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name];
        case PROCESSING_SECTION:
            return PROCESSING_SECTION_NAME;
        case MY_MAPS_SECTION:
            return MY_MAPS_SECTION_NAME;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[ObservationTableHeaderView alloc] initWithName:[self tableView:tableView titleForHeaderInSection:section] andScheme:self.scheme];
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Layer *layer = [self layerFromIndexPath:indexPath];
    NSUInteger section = [self getSectionFromLayer:layer];
    if (section == DOWNLOADED_SECTION) {
        CacheOverlay * cacheOverlay = [self findOverlayByRemoteId:layer.remoteId];
        if (cacheOverlay.expanded) {
            return 58.0f + (58.0f * [cacheOverlay getChildren].count);
        }
        return 58.0f;
    } else if (section == MY_MAPS_SECTION) {
        CacheOverlay *cacheOverlay = [self.cacheOverlays getByCacheName:layer.name];
        if (cacheOverlay.expanded) {
            return 58.0f + (58.0f * [cacheOverlay getChildren].count);
        }
        return 58.0f;
    }
    
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"onlineLayerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"onlineLayerCell"];
    }
    
    cell.textLabel.textColor =  [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    cell.detailTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    cell.imageView.tintColor = self.scheme.colorScheme.primaryColor;
    [cell.imageView setImage:nil];
    cell.accessoryView = nil;

    Layer *layer = [self layerFromIndexPath:indexPath];
    NSUInteger section = [self getSectionFromLayer:layer];

    if (section == AVAILABLE_SECTION) {
        cell.textLabel.text = layer.name;

        if (!layer.downloading) {
            if (layer.file) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [NSByteCountFormatter stringFromByteCount:[[[layer file] valueForKey:@"size"] intValue] countStyle:NSByteCountFormatterCountStyleFile]];
            } else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Static feature data"];
            }

            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download"]];
            [imageView setTintColor:self.scheme.colorScheme.primaryColor];
            cell.accessoryView = imageView;
        } else {
            if (layer.file) {
                uint64_t downloadBytes = [layer.downloadedBytes longLongValue];
                           NSLog(@"Download bytes %ld", (long)downloadBytes);
                           cell.detailTextLabel.text = [NSString stringWithFormat:@"Downloading, Please wait: %@ of %@",
                                                        [NSByteCountFormatter stringFromByteCount:downloadBytes countStyle:NSByteCountFormatterCountStyleFile],
                                                        [NSByteCountFormatter stringFromByteCount:[[[layer file] valueForKey:@"size"] intValue] countStyle:NSByteCountFormatterCountStyleFile]];
            } else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Loading static feature data, Please wait"];
            }
           
            UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
            [activityIndicator setFrame:CGRectMake(0, 0, 24, 24)];
            [activityIndicator startAnimating];
            activityIndicator.color = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
            cell.accessoryView = activityIndicator;
        }
    } else if (section == DOWNLOADED_SECTION) {
        if ([layer isKindOfClass:[StaticLayer class]]) {
            StaticLayer *staticLayer = (StaticLayer *)layer;
            cell.textLabel.text = layer.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu features", (unsigned long)[(NSArray *)[staticLayer.data objectForKey:@"features"] count]];
            
            [cell.imageView setImage:[UIImage imageNamed:@"marker_outline"]];
                        
            UISwitch *cacheSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            cacheSwitch.on = [self.selectedStaticLayers containsObject:layer.remoteId];
            cacheSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
            cacheSwitch.tag = indexPath.row;
            [cacheSwitch addTarget:self action:@selector(staticLayerToggled:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = cacheSwitch;
        } else {
            CacheOverlayTableCell *gpCell = [tableView dequeueReusableCellWithIdentifier:@"geoPackageLayerCell"];
            if (!gpCell) {
                gpCell = [[CacheOverlayTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"geoPackageLayerCell" scheme: self.scheme];
            }
            gpCell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            
            CacheOverlay * cacheOverlay = [self findOverlayByRemoteId:layer.remoteId];
            gpCell.overlay = cacheOverlay;
            gpCell.mageLayer = layer;
            gpCell.mainTable = self.tableView;
            [gpCell configure];
            [gpCell bringSubviewToFront:gpCell.tableView];

            return gpCell;
        }
    } else if (section == MY_MAPS_SECTION) {
        CacheOverlay *localOverlay = [self.cacheOverlays getByCacheName:layer.name];
        if ([localOverlay isKindOfClass:[GeoPackageCacheOverlay class]]) {
            CacheOverlayTableCell *gpCell = [tableView dequeueReusableCellWithIdentifier:@"geoPackageLayerCell"];
            if (!gpCell) {
                gpCell = [[CacheOverlayTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"geoPackageLayerCell" scheme: self.scheme];
            }
            gpCell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            gpCell.overlay = localOverlay;
            gpCell.mainTable = self.tableView;
            gpCell.mageLayer = nil;
            [gpCell configure];
            [gpCell bringSubviewToFront:gpCell.tableView];
            return gpCell;
        } else {
            cell.textLabel.text = [localOverlay getCacheName];
            cell.detailTextLabel.text = [localOverlay getInfo];
            [cell.imageView setImage:[UIImage imageNamed:[localOverlay getIconImageName]]];
            
            CacheActiveSwitch *cacheSwitch = [[CacheActiveSwitch alloc] initWithFrame:CGRectZero];
            cacheSwitch.on = localOverlay.enabled;
            cacheSwitch.overlay = localOverlay;
            cacheSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
            [cacheSwitch addTarget:self action:@selector(activeChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = cacheSwitch;
        }
    } else if (section == PROCESSING_SECTION) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSString *processingOverlay = [[self.cacheOverlays getProcessing] objectAtIndex:indexPath.row];
        cell.textLabel.text = processingOverlay;
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[documentsDirectory stringByAppendingPathComponent: processingOverlay] error:nil];
        cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:(unsigned long long)attrs.fileSize countStyle:NSByteCountFormatterCountStyleFile];
        [cell.imageView setImage:nil];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        [activityIndicator startAnimating];
        activityIndicator.color = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        cell.accessoryView = activityIndicator;
    } else {
        cell.textLabel.text = layer.name;
        cell.detailTextLabel.text = nil;
        cell.accessoryView = nil;
    }
    return cell;
}

- (IBAction)staticLayerToggled: (UISwitch *)sender {
    Layer *layer = [self layerFromIndexPath: [NSIndexPath indexPathForRow:sender.tag inSection:0]];
    if (sender.on) {
        [self.selectedStaticLayers addObject:layer.remoteId];
    } else {
        [self.selectedStaticLayers removeObject:layer.remoteId];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@{[[Server currentEventId] stringValue] :[self.selectedStaticLayers allObjects]} forKey:@"selectedStaticLayers"];
    [defaults synchronize];
}

- (void) retrieveLayerData: (Layer *) layer {
    if ([layer isKindOfClass:[StaticLayer class]]) {
        [StaticLayer fetchStaticLayerData:[Server currentEventId] layer:(StaticLayer *)layer];
    } else {
        [Layer cancelGeoPackageDownload: layer];
        [self startGeoPackageDownload:layer];
    }
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    Layer *layer = [self layerFromIndexPath:indexPath];
    NSUInteger section = [self getSectionFromLayer:layer];

    if (section == AVAILABLE_SECTION) {
        if (layer.downloading) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Layer is Currently Downloading"
                                                                           message:[NSString stringWithFormat:@"It appears the %@ layer is currently being downloaded, however if the download has failed you can restart it.", layer.name]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            __weak typeof(self) weakSelf = self;

            [alert addAction:[UIAlertAction actionWithTitle:@"Restart Download" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf retrieveLayerData:layer];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel Download" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf cancelGeoPackageDownload:layer];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Continue Downloading" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"Do not restart the download");
            }]];
            
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        } else {
            [self retrieveLayerData:layer];
        }
    } else if (section == DOWNLOADED_SECTION) {
        if ([layer isKindOfClass:[StaticLayer class]]) {
            UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
            
            if (cell.accessoryType == UITableViewCellAccessoryNone) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [self.selectedStaticLayers addObject:layer.remoteId];
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                [self.selectedStaticLayers removeObject:layer.remoteId];
            }
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:@{[[Server currentEventId] stringValue] :[self.selectedStaticLayers allObjects]} forKey:@"selectedStaticLayers"];
            [defaults synchronize];
            
            [tableView reloadData];
        }
    }
}

- (void) startGeoPackageDownload: (Layer *) layer {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
        Layer *localLayer = [layer MR_inContext:localContext];
        localLayer.downloading = YES;
        localLayer.downloadedBytes = 0;
    } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
        [Layer downloadGeoPackage:layer success:^{
        } failure:^(NSError * _Nonnull error) {
        }];
    }];
}

- (void) cancelGeoPackageDownload: (Layer *) layer {
    [Layer cancelGeoPackageDownload: layer];
}

- (IBAction)activeChanged:(CacheActiveSwitch *)sender {
    CacheOverlay * cacheOverlay = sender.overlay;
    [cacheOverlay setEnabled:sender.on];
    
    BOOL modified = false;
    for(CacheOverlay * childCache in [cacheOverlay getChildren]){
        if(childCache.enabled != cacheOverlay.enabled){
            [childCache setEnabled:cacheOverlay.enabled];
            modified = true;
        }
    }
    
    if(modified){
        [self.tableView reloadData];
    }
    
    [self updateSelectedAndNotify];
}

-(void) updateSelectedAndNotify{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self getSelectedOverlays] forKey:MAGE_SELECTED_CACHES];
    [defaults synchronize];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cacheOverlays notifyListenersExceptCaller:self];
    });
}

-(NSArray *) getSelectedOverlays{
    NSMutableArray * overlays = [[NSMutableArray alloc] init];
    for(CacheOverlay * cacheOverlay in [self.cacheOverlays getOverlays]){
        
        BOOL childAdded = false;
        for(CacheOverlay * childCache in [cacheOverlay getChildren]){
            if(childCache.enabled){
                [overlays addObject:[childCache getCacheName]];
                childAdded = true;
            }
        }
        
        if(!childAdded && cacheOverlay.enabled){
            [overlays addObject:[cacheOverlay getCacheName]];
        }
    }
    return overlays;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
    
    Layer *layer = [[[self.mapsFetchedResultsController.sections objectAtIndex:indexPath.section] objects] objectAtIndex:0];
    NSUInteger section = [self getSectionFromLayer:layer];

    if(section == DOWNLOADED_SECTION || section == MY_MAPS_SECTION) {
        style = UITableViewCellEditingStyleDelete;
    }
    return style;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    
    Layer *editedLayer = [self layerFromIndexPath:indexPath];
    NSUInteger section = [self getSectionFromLayer:editedLayer];
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"Editing style delete");
        if (section == DOWNLOADED_SECTION) {
            if ([editedLayer isKindOfClass:[StaticLayer class]]) {
                StaticLayer *staticLayer = (StaticLayer *)editedLayer;
                [staticLayer removeStaticLayerData];
            } else {
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
                    NSArray<Layer *> *layers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", editedLayer.remoteId] inContext:localContext];
                    for (Layer *layer in layers) {
                        layer.loaded = nil;
                        layer.downloadedBytes = 0;
                        layer.downloading = NO;
                    }
                } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
                    GeoPackageCacheOverlay *cacheOverlay = (GeoPackageCacheOverlay *)[self findOverlayByRemoteId:editedLayer.remoteId];
                    if (cacheOverlay) {
                        [weakSelf deleteCacheOverlay:cacheOverlay];
                    }
                    [weakSelf.tableView reloadData];
                }];
            }
        } else if (section == MY_MAPS_SECTION) {
            CacheOverlay *localOverlay = [self.cacheOverlays getByCacheName:editedLayer.name];
            [self deleteCacheOverlay:localOverlay];
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
                Layer *localLayer = [editedLayer MR_inContext: localContext];
                [localLayer MR_deleteEntity];
            }];
        }
    }
}

-(void)deleteCacheOverlay: (CacheOverlay *) cacheOverlay{
    switch([cacheOverlay getType]){
        case XYZ_DIRECTORY:
            [self deleteXYZCacheOverlay:(XYZDirectoryCacheOverlay *)cacheOverlay];
            break;
        case GEOPACKAGE:
            [self deleteGeoPackageCacheOverlay:(GeoPackageCacheOverlay *)cacheOverlay];
            break;
        default:
            break;
    }
    [self.cacheOverlays removeCacheOverlay:cacheOverlay];
}

-(void) deleteXYZCacheOverlay: (XYZDirectoryCacheOverlay *) xyzCacheOverlay{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[xyzCacheOverlay getDirectory] error:&error];
    if(error){
        NSLog(@"Error deleting XYZ cache directory: %@. Error: %@", [xyzCacheOverlay getDirectory], error);
    }
}

-(void) deleteGeoPackageCacheOverlay: (GeoPackageCacheOverlay *) geoPackageCacheOverlay{
    
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    if(![manager delete:[geoPackageCacheOverlay getName]]){
        NSLog(@"Error deleting GeoPackage cache file: %@", [geoPackageCacheOverlay getName]);
    }
    [self.cacheOverlays removeCacheOverlay:geoPackageCacheOverlay];
}

@end
