//
//  GeoPackageImporter.h
//  MAGE
//
//  Created by Daniel Barela on 3/15/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GeoPackageImporter : NSObject

- (BOOL) handleGeoPackageImport: (NSString *) filePath;
- (void) processOfflineMapArchives;
-(BOOL) importGeoPackageFileAsLink: (NSString *) path andMove: (BOOL) moveFile withLayerId: (NSNumber *) remoteId;

@end

NS_ASSUME_NONNULL_END
