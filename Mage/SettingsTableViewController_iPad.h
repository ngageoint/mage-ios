//
//  SettingsTableViewController_iPad.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol SettingSelectionDelegate <NSObject>
@required
-(void) selectedSetting:(NSString *) storyboardId;
@end

@interface SettingsTableViewController_iPad : UITableViewController<CLLocationManagerDelegate>

@property(nonatomic, weak) id<SettingSelectionDelegate> settingSelectionDelegate;

@end
