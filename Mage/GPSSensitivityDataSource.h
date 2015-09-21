//
//  GPSSensitivityDataSource.h
//  MAGE
//
//

#import <Foundation/Foundation.h>

@protocol GPSSensistivitySelected <NSObject>

-(void) gpsSensistivitySelected:(NSString *) value withLabel:(NSString *) label;

@end

@interface GPSSensitivityDataSource : NSObject

@property (nonatomic, weak) NSArray *labels;
@property (nonatomic, weak) NSArray *values;

@property (nonatomic, weak) IBOutlet id<GPSSensistivitySelected> gpsSensistivitySelectedDelegate;

@end
