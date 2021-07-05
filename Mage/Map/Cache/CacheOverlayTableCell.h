//
//  CacheOverlayTableCell.h
//  MAGE
//
//  Created by Brian Osborn on 1/11/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CacheActiveSwitch.h"
#import "CacheOverlay.h"
#import "Layer.h"
#import <MaterialComponents/MDCContainerScheme.h>

@interface CacheOverlayTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet CacheActiveSwitch *active;
@property (weak, nonatomic) IBOutlet UIImageView *tableType;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) CacheOverlay *overlay;
@property (strong, nonatomic) Layer *mageLayer;
@property (strong, nonatomic) UITableView *mainTable;
@property (strong, nonatomic) UITableView *tableView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier scheme: (id<MDCContainerScheming>) containerScheme;
- (void) configure;

@end
