//
//  OfflineMapTableViewController.m
//  MAGE
//
//

#import "OfflineMapTableViewController.h"
#import "CacheOverlays.h"

@interface OfflineMapTableViewController ()

@property (nonatomic, strong) NSArray *processingOfflineMaps;
@property (nonatomic, strong) CacheOverlays *cacheOverlays;

@end

@implementation OfflineMapTableViewController

bool originalNavBarHidden;

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.processingOfflineMaps = [defaults objectForKey:@"processingOfflineMaps"];
    self.cacheOverlays = [CacheOverlays getInstance];
    [self.cacheOverlays registerListener:self];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void) cacheOverlaysUpdated: (NSArray<CacheOverlay *> *) cacheOverlays{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.processingOfflineMaps = [defaults objectForKey:@"processingOfflineMaps"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tableView {
    return self.processingOfflineMaps.count > 0 ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.processingOfflineMaps.count > 0 && section == 0) {
        return self.processingOfflineMaps.count;
    } else {
        return [self.cacheOverlays count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.processingOfflineMaps.count > 0 && section == 0) {
        return @"Extracting Archives";
    } else {
        return @"Offline Maps";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.processingOfflineMaps.count > 0 && [indexPath section] == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"processingOfflineMapCell" forIndexPath:indexPath];
        UILabel *textLabel = (UILabel *)[cell viewWithTag:100];
        textLabel.text = [self.processingOfflineMaps objectAtIndex:[indexPath row]];
        
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"availableOfflineMapCell" forIndexPath:indexPath];
        CacheOverlay * cacheOverlay = [self.cacheOverlays atIndex:[indexPath row]];
        cell.textLabel.text = [cacheOverlay getName];
        
        if (cacheOverlay.enabled) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.selected = YES;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        return cell;
    }
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableSet * selectedOfflineMaps = [NSMutableSet setWithArray:[defaults objectForKey:@"selectedOfflineMaps"]];
    
    CacheOverlay * cacheOverlay = [self.cacheOverlays atIndex:[indexPath row]];
    NSString * cacheName = [cacheOverlay getCacheName];
    
    UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cacheOverlay.enabled = true;
        [selectedOfflineMaps addObject:cacheName];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cacheOverlay.enabled = false;
        [selectedOfflineMaps removeObject:cacheName];
    }
    
    [defaults setObject:[selectedOfflineMaps allObjects] forKey:@"selectedOfflineMaps"];
    [defaults synchronize];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cacheOverlays notifyListenersExceptCaller:self];
    });
}

@end
