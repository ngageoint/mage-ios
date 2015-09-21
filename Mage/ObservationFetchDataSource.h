//
//  ObservationFetchDataSource.h
//  MAGE
//
//

#import <Foundation/Foundation.h>

@protocol ObservationFetchIntervalSelected <NSObject>

-(void) observationFetchIntervalSelected:(NSString *) value withLabel:(NSString *) label;

@end


@interface ObservationFetchDataSource : NSObject

@property (nonatomic, weak) NSArray *labels;
@property (nonatomic, weak) NSArray *values;

@property (nonatomic, weak) IBOutlet id<ObservationFetchIntervalSelected> observationFetchIntervalSelectedDelegate;

@end
