//
//  OfflineMapTableViewController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "CacheOverlayListener.h"
#import <MaterialComponents/MDCContainerScheme.h>
#import "MAGE-Swift.h"

@interface OfflineMapTableViewController : UITableViewController<CacheOverlayListener>

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme context: (NSManagedObjectContext *) context;

@end
