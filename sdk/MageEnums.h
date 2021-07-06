//
//  MageEnums.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

typedef enum state {
    Archive = 0,
    Active = 1
} State;

@interface NSString (MageEnums)

- (State)StateEnumFromString;
- (int)IntFromStateEnum;
- (NSString *)StringFromStateInt: (int) stateInt;

@end
