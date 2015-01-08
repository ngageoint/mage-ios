
#import <Foundation/Foundation.h>

@interface Recording : NSObject

@property (nonatomic, strong) NSString *mediaType;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *mediaTempFolder;
@property (nonatomic, strong) NSNumber *recordingLength;

@end
