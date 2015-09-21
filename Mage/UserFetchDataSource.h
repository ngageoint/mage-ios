//
//  UserFetchDataSource.h
//  MAGE
//
//

#import <Foundation/Foundation.h>

@protocol UserFetchIntervalSelected <NSObject>

-(void) userFetchIntervalSelected:(NSString *) value withLabel:(NSString *) label;

@end

@interface UserFetchDataSource : NSObject

@property (nonatomic, weak) NSArray *labels;
@property (nonatomic, weak) NSArray *values;

@property (nonatomic, weak) IBOutlet id<UserFetchIntervalSelected> userFetchIntervalSelectedDelegate;

@end
