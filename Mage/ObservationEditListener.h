//
//  ObservationEditListener.h
//  Mage
//
//

#import <Foundation/Foundation.h>

@protocol ObservationEditListener <NSObject>

@required

- (void) observationField: (id) field valueChangedTo: (id) value reloadCell: (BOOL) reload;

@end
