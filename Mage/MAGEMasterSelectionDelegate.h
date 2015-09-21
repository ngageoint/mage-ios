//
//  MAGEMasterSelectionDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <Observation.h>
#import <User.h>

@protocol MAGEMasterSelectionDelegate <NSObject>

@required

-(void) selectedObservation: (Observation *) observation;
-(void) selectedUser: (User *) user;

@end
