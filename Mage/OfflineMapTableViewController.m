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
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"
#import "StaticLayer.h"
#import "Layer.h"
#import "Server.h"
#import "Event.h"

@interface OfflineMapTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) CacheOverlays *cacheOverlays;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshLayersButton;
@property (nonatomic, strong) NSMutableSet *selectedStaticLayers;
@property (nonatomic, strong) NSFetchedResultsController *mapsFetchedResultsController;
@property (nonatomic) BOOL hadLoaded;
@end

@implementation OfflineMapTableViewController

static const NSInteger DOWNLOADED_SECTION = 0;
static const NSInteger MY_MAPS_SECTION = 1;
static const NSInteger AVAILABLE_SECTION = 2;
static const NSInteger PROCESSING_SECTION = 3;

static NSString *DOWNLOADED_SECTION_NAME = @"%@ Maps";
static NSString *MY_MAPS_SECTION_NAME = @"My Maps";
static NSString *AVAILABLE_SECTION_NAME = @"Available Maps";
static NSString *PROCESSING_SECTION_NAME = @"Extracting Archives";

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    [self.tableView reloadData];
}

- (instancetype) init {
    return [super initWithStyle:UITableViewStyleGrouped];
}

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh Layers" style:UIBarButtonItemStylePlain target:self action:@selector(refreshLayers:)];
    
    self.mapsFetchedResultsController = [Layer MR_fetchAllGroupedBy:@"loaded" withPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ AND (type == %@ OR type == %@)", [Server currentEventId], @"GeoPackage", @"Feature"] sortedBy:@"loaded,name:YES" ascending:NO delegate:self];
    [self.mapsFetchedResultsController performFetch:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(geoPackageImported:) name: GeoPackageImported object:nil];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.selectedStaticLayers = [NSMutableSet setWithArray:[defaults valueForKeyPath:[NSString stringWithFormat: @"selectedStaticLayers.%@", [Server currentEventId]]]];
    
    self.cacheOverlays = [CacheOverlays getInstance];
    [self.cacheOverlays registerListener:self];
    
    [self registerForThemeChanges];
    
    self.hadLoaded = [self hasLoadedSection];
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

- (BOOL) hasLoadedSection {
    return ((Layer *)[[[[self.mapsFetchedResultsController sections] objectAtIndex:0] objects] objectAtIndex:0]).loaded;
}

- (Layer *) layerFromIndexPath: (NSIndexPath *) indexPath {
    Layer *layer = nil;
    
    if (indexPath.section == DOWNLOADED_SECTION) {
        layer = [self.mapsFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    } else if (indexPath.section == AVAILABLE_SECTION) {
        if ([self hasLoadedSection]) {
            layer = [self.mapsFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:1]];
        } else {
            layer = [self.mapsFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        }
    }
    return layer;
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    Layer *layer = (Layer *)anObject;

    NSIndexPath *correctedIndexPath = indexPath;
    if ((!self.hadLoaded && indexPath.section == 0)
        || (self.hadLoaded && indexPath.section == 1)) {
        correctedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:2];
    }
    NSIndexPath *correctedNewIndexPath = newIndexPath;
    if (([self hasLoadedSection] && newIndexPath.section == 1)
        || (![self hasLoadedSection] && newIndexPath.section == 0)) {
        correctedNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:2];
    }
    if (type == NSFetchedResultsChangeMove) {
        if(!layer.loaded) {
            correctedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
            correctedNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:2];
        } else {
            correctedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:2];
            correctedNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:0];
        }
    }
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertRowsAtIndexPaths:@[correctedNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteRowsAtIndexPaths:@[correctedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate: {
            // 2019-10-23 DRB (iOS 13): This is a total hack.  If the first row in the available section is reloaded to show the download progress
            // it still shows an animation and bounces the row.  Does not matter if you try to put it in a performWithoutAnimation block
            // or any other way.  You should be able to just do reloadRowsAtIndexPaths (the else block) if this ever gets fixed.
            // Has been a bug since at least ios5: https://stackoverflow.com/questions/4557930/uitableview-reloadrowsatindexpaths-performing-animation-when-it-shouldnt
            if (correctedIndexPath.section == AVAILABLE_SECTION && correctedIndexPath.row == 0) {
                Layer *layer = (Layer *)anObject;
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:correctedIndexPath];
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
                [self.tableView reloadRowsAtIndexPaths:@[correctedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
        case NSFetchedResultsChangeMove:
            [[self tableView] deleteRowsAtIndexPaths:@[correctedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] insertRowsAtIndexPaths:@[correctedNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [[self tableView] endUpdates];
    self.hadLoaded = [self hasLoadedSection];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tableView {
    return ([self.cacheOverlays getProcessing].count > 0 ? 4 : 3);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == DOWNLOADED_SECTION) {
        return [self hasLoadedSection] ? [[[self.mapsFetchedResultsController sections] objectAtIndex:0] numberOfObjects] : 0;
    } else if (section == AVAILABLE_SECTION) {
        return [[[self.mapsFetchedResultsController sections] objectAtIndex:[self hasLoadedSection] ? 1 : 0] numberOfObjects];
    } else if (section == MY_MAPS_SECTION) {
        return [self.cacheOverlays getLocallyLoadedOverlays].count;
    } else if (section == PROCESSING_SECTION) {
        return [self.cacheOverlays getProcessing].count;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == DOWNLOADED_SECTION) {
        return [NSString stringWithFormat:DOWNLOADED_SECTION_NAME, [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name];
    } else if (section == AVAILABLE_SECTION) {
        return AVAILABLE_SECTION_NAME;
    } else if (section == PROCESSING_SECTION) {
        return PROCESSING_SECTION_NAME;
    } else {
        return MY_MAPS_SECTION_NAME;
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[ObservationTableHeaderView alloc] initWithName:[self tableView:tableView titleForHeaderInSection:section]];
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Layer *layer = [self layerFromIndexPath:indexPath];
    if (indexPath.section == DOWNLOADED_SECTION) {
        CacheOverlay * cacheOverlay = [self findOverlayByRemoteId:layer.remoteId];
        if (cacheOverlay.expanded) {
            return 58.0f + (58.0f * [cacheOverlay getChildren].count);
        }
        return 58.0f;
    } else if (indexPath.section == MY_MAPS_SECTION) {
        CacheOverlay *cacheOverlay = [[self.cacheOverlays getLocallyLoadedOverlays] objectAtIndex:indexPath.row];
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
        cell.textLabel.textColor = [UIColor primaryText];
        cell.detailTextLabel.textColor = [UIColor secondaryText];
        cell.backgroundColor = [UIColor dialog];
        cell.imageView.tintColor = [UIColor brand];
    }

    Layer *layer = [self layerFromIndexPath:indexPath];
    if (indexPath.section == AVAILABLE_SECTION) {
        cell.textLabel.text = layer.name;

        if (!layer.downloading) {
            if (layer.file) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [NSByteCountFormatter stringFromByteCount:[[[layer file] valueForKey:@"size"] intValue] countStyle:NSByteCountFormatterCountStyleFile]];
            } else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Static feature data"];
            }

            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download"]];
            [imageView setTintColor:[UIColor brand]];
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
           
            UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [activityIndicator setFrame:CGRectMake(0, 0, 24, 24)];
            [activityIndicator startAnimating];
            activityIndicator.color = [UIColor secondaryText];
            cell.accessoryView = activityIndicator;
        }
    } else if (indexPath.section == DOWNLOADED_SECTION) {
        if ([layer isKindOfClass:[StaticLayer class]]) {
            StaticLayer *staticLayer = (StaticLayer *)layer;
            cell.textLabel.text = layer.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu features", (unsigned long)[(NSArray *)[staticLayer.data objectForKey:@"features"] count]];
            
            [cell.imageView setImage:[UIImage imageNamed:@"marker_outline"]];
            
            UISwitch *cacheSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            cacheSwitch.on = [self.selectedStaticLayers containsObject:layer.remoteId];
            cacheSwitch.onTintColor = [UIColor themedButton];
            cacheSwitch.tag = indexPath.row;
            [cacheSwitch addTarget:self action:@selector(staticLayerToggled:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = cacheSwitch;
        } else {
            CacheOverlayTableCell *gpCell = [tableView dequeueReusableCellWithIdentifier:@"geoPackageLayerCell"];
            if (!gpCell) {
                gpCell = [[CacheOverlayTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"geoPackageLayerCell"];
            }
            
            CacheOverlay * cacheOverlay = [self findOverlayByRemoteId:layer.remoteId];
            gpCell.overlay = cacheOverlay;
            gpCell.mageLayer = layer;
            gpCell.mainTable = self.tableView;
            [gpCell configure];
            return gpCell;
        }
    } else if (indexPath.section == MY_MAPS_SECTION) {
        CacheOverlay *localOverlay = [[self.cacheOverlays getLocallyLoadedOverlays] objectAtIndex:indexPath.row];
        if ([localOverlay isKindOfClass:[GeoPackageCacheOverlay class]]) {
            CacheOverlayTableCell *gpCell = [tableView dequeueReusableCellWithIdentifier:@"geoPackageLayerCell"];
            if (!gpCell) {
                gpCell = [[CacheOverlayTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"geoPackageLayerCell"];
            }
            gpCell.overlay = localOverlay;
            gpCell.mainTable = self.tableView;
            [gpCell configure];
            return gpCell;
        } else {
            cell.textLabel.text = [localOverlay getCacheName];
            cell.detailTextLabel.text = [localOverlay getInfo];
            [cell.imageView setImage:[UIImage imageNamed:[localOverlay getIconImageName]]];
            
            CacheActiveSwitch *cacheSwitch = [[CacheActiveSwitch alloc] initWithFrame:CGRectZero];
            cacheSwitch.on = localOverlay.enabled;
            cacheSwitch.overlay = localOverlay;
            cacheSwitch.onTintColor = [UIColor themedButton];
            [cacheSwitch addTarget:self action:@selector(activeChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = cacheSwitch;
        }
    } else if (indexPath.section == PROCESSING_SECTION) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSString *processingOverlay = [[self.cacheOverlays getProcessing] objectAtIndex:indexPath.row];
        cell.textLabel.text = processingOverlay;
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[documentsDirectory stringByAppendingPathComponent: processingOverlay] error:nil];
        cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:(unsigned long long)attrs.fileSize countStyle:NSByteCountFormatterCountStyleFile];
        [cell.imageView setImage:nil];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityIndicator startAnimating];
        activityIndicator.color = [UIColor secondaryText];
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
        [self startGeoPackageDownload:layer];
    }
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == AVAILABLE_SECTION) {
        Layer *layer = [self.mapsFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:[self hasLoadedSection] ? 1 : 0]];
        if (layer.downloading) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Layer is Currently Downloading"
                                                                           message:[NSString stringWithFormat:@"It appears the %@ layer is currently being downloaded, however if the download has failed you can restart it.", layer.name]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            __weak typeof(self) weakSelf = self;

            [alert addAction:[UIAlertAction actionWithTitle:@"Restart Download" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf retrieveLayerData:layer];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Continue Downloading" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"Do not restart the download");
            }]];
            
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        } else {
            [self retrieveLayerData:layer];
        }
    } else if (indexPath.section == DOWNLOADED_SECTION) {
        Layer *layer = [self.mapsFetchedResultsController objectAtIndexPath:indexPath];
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

    if(indexPath.section == DOWNLOADED_SECTION || indexPath.section == MY_MAPS_SECTION) {
        style = UITableViewCellEditingStyleDelete;
    }
    return style;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    
    Layer *editedLayer = [self layerFromIndexPath:indexPath];

    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"Editing style delete");
        if (indexPath.section == DOWNLOADED_SECTION) {
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
        } else if (indexPath.section == MY_MAPS_SECTION) {
            CacheOverlay *localOverlay = [[self.cacheOverlays getLocallyLoadedOverlays] objectAtIndex:indexPath.row];
            [self deleteCacheOverlay:localOverlay];
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
    
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory getManager];
    if(![manager delete:[geoPackageCacheOverlay getName]]){
        NSLog(@"Error deleting GeoPackage cache file: %@", [geoPackageCacheOverlay getName]);
    }
}

@end
