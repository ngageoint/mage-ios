//
//  StaticLayerTableViewCell.h
//  MAGE
//
//

#import <UIKit/UIKit.h>

@interface StaticLayerTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *layerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *featureCountLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end
