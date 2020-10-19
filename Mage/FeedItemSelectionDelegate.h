//
//  FeedItemSelectionDelegate.h
//  MAGE
//
//  Created by Daniel Barela on 8/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FeedItemSelectionDelegate <NSObject>

@required

- (void) feedItemSelected: (FeedItem *) feedItem;

@end

NS_ASSUME_NONNULL_END
