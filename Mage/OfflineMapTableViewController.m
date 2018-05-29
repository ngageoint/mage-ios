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

@interface OfflineMapTableViewController ()

@property (nonatomic, strong) NSArray *processingCaches;
@property (nonatomic, strong) CacheOverlays *cacheOverlays;
@property (nonatomic, strong) NSMutableArray<CacheOverlay *> *tableCells;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CacheOverlay *> *cacheNamesToOverlays;

@end

@implementation OfflineMapTableViewController

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    
    [self.tableView reloadData];
}

- (instancetype) init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    return self;
}

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    [self registerForThemeChanges];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    
    self.cacheOverlays = [CacheOverlays getInstance];
    [self.cacheOverlays registerListener:self];
    [self update];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void) cacheOverlaysUpdated: (NSArray<CacheOverlay *> *) cacheOverlays{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAndReloadData];
    });
}

-(void) updateAndReloadData{
    [self update];
    [self.tableView reloadData];
}

-(void) update{
    self.processingCaches = [self.cacheOverlays getProcessing];
    self.tableCells = [[NSMutableArray alloc] init];
    self.cacheNamesToOverlays = [[NSMutableDictionary alloc] init];
    for(CacheOverlay * cacheOverlay in [self.cacheOverlays getOverlays]){
        [self.tableCells addObject:cacheOverlay];
        [self.cacheNamesToOverlays setObject:cacheOverlay forKey:[cacheOverlay getCacheName]];
        if(cacheOverlay.expanded){
            for(CacheOverlay * childCacheOverlay in [cacheOverlay getChildren]){
                [self.tableCells addObject:childCacheOverlay];
                [self.cacheNamesToOverlays setObject:childCacheOverlay forKey:[childCacheOverlay getCacheName]];
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tableView {
    return self.processingCaches.count > 0 ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    if (self.processingCaches.count > 0 && section == 0) {
        count = self.processingCaches.count;
    } else {
        count = [self.tableCells count];
    }
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.processingCaches.count > 0 && section == 0) {
        return @"Extracting Archives";
    } else {
        return @"Overlay Maps";
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[ObservationTableHeaderView alloc] initWithName:[self tableView:tableView titleForHeaderInSection:section]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    if (self.processingCaches.count > 0 && [indexPath section] == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"processingOfflineMapCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"processingOfflineMapCell"];
        }
        cell.textLabel.text = [self.processingCaches objectAtIndex:[indexPath row]];
        cell.textLabel.textColor = [UIColor primaryText];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityIndicator setFrame:CGRectZero];
        [activityIndicator startAnimating];
        activityIndicator.color = [UIColor secondaryText];
        cell.accessoryView = activityIndicator;
    } else {
        CacheOverlay * cacheOverlay = [self.tableCells objectAtIndex:[indexPath row]];
        
        UIImage * cellImage = nil;
        NSString * typeImage = [cacheOverlay getIconImageName];
        if(typeImage != nil){
            cellImage = [UIImage imageNamed:typeImage];
        }
        
        if([cacheOverlay isChild]){
            cell = [tableView dequeueReusableCellWithIdentifier:@"childCacheOverlayCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"childCacheOverlayCell"];
            }
            cell.textLabel.text = [cacheOverlay getName];
            cell.detailTextLabel.text = [cacheOverlay getInfo];
            cell.textLabel.textColor = [UIColor primaryText];
            cell.detailTextLabel.textColor = [UIColor secondaryText];
            if (cellImage != nil) {
                [cell.imageView setImage:cellImage];
                cell.imageView.tintColor = [UIColor brand];
            }
            
            CacheActiveSwitch *cacheSwitch = [[CacheActiveSwitch alloc] initWithFrame:CGRectZero];
            cacheSwitch.on = cacheOverlay.enabled;
            cacheSwitch.overlay = cacheOverlay;
            cacheSwitch.onTintColor = [UIColor themedButton];
            [cacheSwitch addTarget:self action:@selector(childActiveChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = cacheSwitch;
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"cacheOverlayCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cacheOverlayCell"];
            }
            cell.textLabel.text = [cacheOverlay getName];
            cell.textLabel.textColor = [UIColor primaryText];
            if (cellImage != nil) {
                [cell.imageView setImage:cellImage];
                cell.imageView.tintColor = [UIColor brand];
            }
            
            CacheActiveSwitch *cacheSwitch = [[CacheActiveSwitch alloc] initWithFrame:CGRectZero];
            cacheSwitch.on = cacheOverlay.enabled;
            cacheSwitch.overlay = cacheOverlay;
            cacheSwitch.onTintColor = [UIColor themedButton];
            [cacheSwitch addTarget:self action:@selector(activeChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = cacheSwitch;
        }
    }
    
    cell.backgroundColor = [UIColor background];
    return cell;
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    
    if(self.processingCaches.count == 0 || [indexPath section] == 1){
        CacheOverlay * cacheOverlay = [self.tableCells objectAtIndex:[indexPath row]];
        if([cacheOverlay getSupportsChildren]){
            [cacheOverlay setExpanded:!cacheOverlay.expanded];
            [self updateAndReloadData];
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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

- (IBAction)childActiveChanged:(CacheActiveSwitch *)sender {
    
    CacheOverlay * cacheOverlay = sender.overlay;
    CacheOverlay * parentOverlay = [cacheOverlay getParent];
    
    [cacheOverlay setEnabled:sender.on];
    
    BOOL parentEnabled = true;
    if(!cacheOverlay.enabled){
        parentEnabled = false;
        for(CacheOverlay * childOverlay in [parentOverlay getChildren]){
            if(childOverlay.enabled){
                parentEnabled = true;
                break;
            }
        }
    }
    if(parentEnabled != parentOverlay.enabled){
        [parentOverlay setEnabled:parentEnabled];
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
    
    if(self.processingCaches.count == 0 || [indexPath section] == 1){
        CacheOverlay * cacheOverlay = [self.tableCells objectAtIndex:[indexPath row]];
        if(![cacheOverlay isChild]){
            style = UITableViewCellEditingStyleDelete;
        }
    }
    
    return style;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        CacheOverlay * cacheOverlay = [self.tableCells objectAtIndex:[indexPath row]];
        [self deleteCacheOverlay:cacheOverlay];
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
