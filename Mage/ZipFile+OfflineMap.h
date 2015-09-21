//
//  ZipFile+Expand.h
//  MAGE
//
//

#import "ZipFile.h"

@interface ZipFile (OfflineMap)

- (NSArray *) expandToPath:(NSString *) path error:(NSError **) error;

@end
