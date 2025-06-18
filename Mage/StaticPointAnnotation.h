//
//  StaticPointAnnotation.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"

@interface StaticPointAnnotation : MapAnnotation

@property (strong, nonatomic) NSDictionary *feature;
@property (strong, nonatomic) NSString *iconUrl;
@property (strong, nonatomic) NSString *layerName;

- (id)initWithFeature:(NSDictionary *) feature;
- (UIView *) detailViewForAnnotation;
- (NSString *) detailTextForAnnotation;

@end
