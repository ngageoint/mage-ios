//
//  ObservationEditViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <Observation.h>
#import "ObservationEditListener.h"
#import "AttachmentCollectionDataStore.h"
#import <GeoPoint.h>

@protocol PropertyEditDelegate <NSObject>
- (void) setValue:(id) value forFieldDefinition:(NSDictionary *) fieldDefinition;
@end

@interface ObservationEditViewController : UIViewController<PropertyEditDelegate>

@property (strong, nonatomic) Observation *observation;
@property (strong, nonatomic) GeoPoint *location;

@property (strong, nonatomic) id<AttachmentSelectionDelegate> attachmentDelegate;

@end
