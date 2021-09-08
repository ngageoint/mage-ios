//
//  FeedItemActionsDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc protocol FeedItemActionsDelegate {
    @objc optional func getDirectionsToFeedItem(_ feedItem: FeedItem, sourceView: UIView?);
    @objc optional func viewFeedItem(feedItem: FeedItem);
    @objc optional func copyLocation(_ location: String);
}
