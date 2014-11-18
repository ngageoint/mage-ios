//
//  ZipFile+Expand.h
//  MAGE
//
//  Created by William Newman on 11/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ZipFile.h"

@interface ZipFile (OfflineMap)

- (NSArray *) expandToPath:(NSString *) path error:(NSError **) error;

@end
