//
//  MageEnums.m
//  mage-ios-sdk
//
//

#import "MageEnums.h"

@implementation NSString (MageEnums)

- (State)StateEnumFromString{
    
    NSDictionary *states = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInteger:Active], @"active",
                            [NSNumber numberWithInteger:Archive], @"archive",
                            nil
                            ];
    
    return (State)[[states objectForKey:self] intValue];
}

- (int)IntFromStateEnum {
    NSDictionary *states = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInteger:Active], @"active",
                            [NSNumber numberWithInteger:Archive], @"archive",
                            nil
                            ];
    return [[states objectForKey:self] intValue];
}

- (NSString *)StringFromStateInt: (int) stateInt {
    NSDictionary *states = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"active", [NSNumber numberWithInteger:Active],
                            @"archive", [NSNumber numberWithInteger:Archive],
                            nil
                            ];
    return (NSString *)[states objectForKey:[NSNumber numberWithInt:stateInt]];
}


@end
