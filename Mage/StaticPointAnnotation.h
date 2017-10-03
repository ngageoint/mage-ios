//
//  StaticPointAnnotation.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"

@interface StaticPointAnnotation : MapAnnotation

@property (weak, nonatomic) NSDictionary *feature;
@property (weak, nonatomic) NSString *iconUrl;

- (id)initWithFeature:(NSDictionary *) feature;

@end
