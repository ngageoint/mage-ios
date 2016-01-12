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

const char ConstantKey;

@interface OfflineMapTableViewController ()

@property (nonatomic, strong) NSArray *processingCaches;
@property (nonatomic, strong) CacheOverlays *cacheOverlays;
@property (nonatomic, strong) NSMutableArray<CacheOverlay *> *tableCells;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CacheOverlay *> *cacheNamesToOverlays;

@end

@implementation OfflineMapTableViewController

#define TAG_DELETE_CACHE 1

bool originalNavBarHidden;

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.processingCaches = [defaults objectForKey:MAGE_PROCESSING_CACHES];
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.processingCaches = [defaults objectForKey:MAGE_PROCESSING_CACHES];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    if (self.processingCaches.count > 0 && [indexPath section] == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"processingOfflineMapCell" forIndexPath:indexPath];
        UILabel *textLabel = (UILabel *)[cell viewWithTag:100];
        textLabel.text = [self.processingCaches objectAtIndex:[indexPath row]];
    } else {
        CacheOverlay * cacheOverlay = [self.tableCells objectAtIndex:[indexPath row]];
        
        UIImage * cellImage = nil;
        NSString * typeImage = [cacheOverlay getIconImageName];
        if(typeImage != nil){
            cellImage = [UIImage imageNamed:typeImage];
        }
        
        if([cacheOverlay isChild]){
            cell = [tableView dequeueReusableCellWithIdentifier:@"childCacheOverlayCell" forIndexPath:indexPath];
            ChildCacheOverlayTableCell * childCacheOverlayCell = (ChildCacheOverlayTableCell *) cell;
            
            [childCacheOverlayCell.name setText:[cacheOverlay getName]];
            childCacheOverlayCell.active.on = cacheOverlay.enabled;
            [childCacheOverlayCell.info setText:[cacheOverlay getInfo]];
            
            if(cellImage != nil){
                [childCacheOverlayCell.tableType setImage:cellImage];
            }
            
            [childCacheOverlayCell.active setOverlay:cacheOverlay];
            
        }else{
            cell = [tableView dequeueReusableCellWithIdentifier:@"cacheOverlayCell" forIndexPath:indexPath];
            CacheOverlayTableCell * cacheOverlayCell = (CacheOverlayTableCell *) cell;
            
            [cacheOverlayCell.name setText:[cacheOverlay getName]];
            cacheOverlayCell.active.on = cacheOverlay.enabled;
            
            if(cellImage != nil){
                [cacheOverlayCell.tableType setImage:cellImage];
            }
            
            [cacheOverlayCell.active setOverlay:cacheOverlay];
            [cacheOverlayCell.deleteButton setOverlay:cacheOverlay];
        }
        
    }
    
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

- (IBAction)deleteCache:(CacheDeleteButton *)sender {
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Delete Cache"
                          message:[NSString stringWithFormat:@"Delete Cache '%@'?", [sender.overlay getName]]
                          delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"Delete",
                          nil];
    alert.tag = TAG_DELETE_CACHE;
    objc_setAssociatedObject(alert, &ConstantKey, sender.overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alert show];

}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
        case TAG_DELETE_CACHE:
            [self handleDeleteCacheWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
    }
}

-(void)handleDeleteCacheWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(buttonIndex > 0){
        CacheOverlay * cacheOverlay = objc_getAssociatedObject(alertView, &ConstantKey);
        if(cacheOverlay != nil){
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
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateAndReloadData];
            });
            if(cacheOverlay.enabled){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.cacheOverlays notifyListenersExceptCaller:self];
                });
            }
        }
    }
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
