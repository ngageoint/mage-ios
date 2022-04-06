//
//  CacheOverlayTableCell.m
//  MAGE
//
//  Created by Brian Osborn on 1/11/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "CacheOverlayTableCell.h"
#import "CacheOverlays.h"
#import "MageConstants.h"
#import "MAGE-Swift.h"

@interface CacheOverlayTableCell()<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation CacheOverlayTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier scheme: (id<MDCContainerScheming>) containerScheme {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        self.tableView.tag = 100;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.scheme = containerScheme;
        [self addSubview:self.tableView];
    }
    return self;
}

 -(void)layoutSubviews {
    [super layoutSubviews];
    UITableView *subMenuTableView = (UITableView *) [self viewWithTag:100];
    subMenuTableView.frame = CGRectMake(0.2, 0.3, self.bounds.size.width, self.bounds.size.height);
}

- (void) configure {
    [self.tableView reloadData];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58.0f;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.overlay getChildren].count == 1 ? 1 : [self.overlay getChildren].count + 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 && [self.overlay getChildren].count != 1) {
        self.overlay.expanded = !self.overlay.expanded;
        [self.tableView reloadData];
        [self.mainTable reloadData];
    }
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cacheOverlayCell"];
    if(cell == nil) {
       cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cacheOverlayCell"];
    }
    cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    cell.detailTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    cell.imageView.tintColor = self.scheme.colorScheme.primaryColorVariant;
    
    if ([self.overlay getChildren].count != 1  && indexPath.row == 0) {
        cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
        cell.detailTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];

        CacheActiveSwitch *cacheSwitch = [[CacheActiveSwitch alloc] initWithFrame:CGRectZero];
        cacheSwitch.on = self.overlay.enabled;
        cacheSwitch.overlay = self.overlay;
        cacheSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
        [cacheSwitch addTarget:self action:@selector(activeChanged:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = cacheSwitch;
        cell.textLabel.text = self.mageLayer ? self.mageLayer.name : [self.overlay getName];
        cell.detailTextLabel.text = [NSString stringWithFormat: @"%lu layer%@", (unsigned long)[self.overlay getChildren].count, [self.overlay getChildren].count == 1 ? @"" : @"s"];
        [cell.imageView setImage:[UIImage imageNamed:@"folder"]];
        
    } else {
        CacheOverlay *cacheOverlay = [self.overlay.getChildren objectAtIndex:[self.overlay getChildren].count == 1 ? indexPath.row : indexPath.row - 1];
        UIImage * cellImage = nil;
        NSString * typeImage = [cacheOverlay getIconImageName];
        if(typeImage != nil){
            cellImage = [UIImage imageNamed:typeImage];
        }
        cell.textLabel.text = [self.overlay getChildren].count == 1 ? self.mageLayer ? self.mageLayer.name : [self.overlay getName] : [cacheOverlay getName];
        cell.detailTextLabel.text = [cacheOverlay getInfo];
        
        if (cellImage != nil) {
            [cell.imageView setImage:cellImage];
        }

        CacheActiveSwitch *cacheSwitch = [[CacheActiveSwitch alloc] initWithFrame:CGRectZero];
        cacheSwitch.on = cacheOverlay.enabled;
        cacheSwitch.overlay = cacheOverlay;
        cacheSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
        [cacheSwitch addTarget:self action:@selector(childActiveChanged:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = cacheSwitch;
    }

    return cell;
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
    NSMutableArray * overlays = [[NSMutableArray alloc] init];
    CacheOverlays *cacheOverlays = [CacheOverlays getInstance];
    for(CacheOverlay * cacheOverlay in [cacheOverlays getOverlays]){

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
    [defaults setObject:overlays forKey:MAGE_SELECTED_CACHES];
    [defaults synchronize];
    dispatch_async(dispatch_get_main_queue(), ^{
        [cacheOverlays notifyListeners];
    });
}

@end
