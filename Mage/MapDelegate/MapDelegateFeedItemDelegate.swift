//
//  MapDelegateFeedItemDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 3/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension MapDelegate : FeedItemDelegate {
    
    public func add(_ feedItem: FeedItem!) {
        if (feedItem.isMappable) {
            self.mapView.addAnnotation(feedItem);
        }
    }
    
    public func remove(_ feedItem: FeedItem!) {
        if (feedItem.isMappable) {
            self.mapView.removeAnnotation(feedItem);
        }
    }
}
