//
//  LocationTimeIntervalDataSource.h
//  MAGE
//
//

#import <Foundation/Foundation.h>

@protocol LocationIntervalSelected <NSObject>

-(void) locationIntervalSelected:(NSString *) value withLabel:(NSString *) label;

@end

@interface LocationTimeIntervalDataSource : NSObject<UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) NSArray *labels;
@property (nonatomic, weak) NSArray *values;

@property (nonatomic, weak) IBOutlet id<LocationIntervalSelected> locationIntervalSelectedDelegate;

@end
