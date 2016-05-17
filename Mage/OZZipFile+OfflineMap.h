//
//  ZipFile+Expand.h
//  MAGE
//
//

#import "Objective-Zip+NSError.h"

@interface OZZipFile (OfflineMap)

- (NSArray *) expandToPath:(NSString *) path error:(NSError **) error;

@end
