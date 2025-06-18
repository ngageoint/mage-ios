//
//  XYZDirectoryCacheOverlay.h
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "CacheOverlay.h"

/**
 *  XYZ Directory of tiles cache overlay
 */
@interface XYZDirectoryCacheOverlay : CacheOverlay

/**
 *  Tile overlay
 */
@property (strong, nonatomic) MKTileOverlay * tileOverlay;
@property (nonatomic) int minZoom;
@property (nonatomic) int maxZoom;
@property (nonatomic) int tileCount;

/**
 *  Initializer
 *
 *  @param name      name
 *  @param directory cache directory
 *
 *  @return new instance
 */
-(instancetype) initWithName: (NSString *) name andDirectory: (NSString *) directory;

/**
 *  Get the cache directory
 *
 *  @return cache directory
 */
-(NSString *) getDirectory;

@end
