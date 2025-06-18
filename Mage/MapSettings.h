//
//  MapSettings.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "AppContainerScheming.h"

@protocol MapSettingsDelegate

- (void) offlineMapsCellTapped;
- (void) onlineMapsCellTapped;

@end

@interface MapSettings : UITableViewController

@property (nonatomic) NSUInteger mapsToDownloadCount;

- (instancetype) initWithDelegate: (id<MapSettingsDelegate>) delegate scheme: (id<AppContainerScheming>) containerScheme;

- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme;

@end
