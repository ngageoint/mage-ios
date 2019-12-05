//
//  MapSettings.h
//  MAGE
//
//

#import <UIKit/UIKit.h>

@protocol MapSettingsDelegate

- (void) offlineMapsCellTapped;
- (void) onlineMapsCellTapped;

@end

@interface MapSettings : UITableViewController

@property (nonatomic) NSUInteger mapsToDownloadCount;

- (instancetype) initWithDelegate: (id<MapSettingsDelegate>) delegate;

@end
