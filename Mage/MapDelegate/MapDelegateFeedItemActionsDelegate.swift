//
//  MapDelegateFeedItemActionsDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

extension MapDelegate : FeedItemActionsDelegate {
    
    func getDirectionsToFeedItem(_ feedItem: FeedItem, sourceView: UIView? = nil) {
        self.mageBottomSheet.dismiss(animated: true, completion: {
            var extraActions: [UIAlertAction] = [];
            extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
                self.observationToNavigateTo = nil;
                self.locationToNavigateTo = kCLLocationCoordinate2DInvalid;
                self.userToNavigateTo = nil;
                self.feedItemToNavigateTo = feedItem;
                var image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: globalContainerScheme().colorScheme.primaryColor);
                if let url: URL = feedItem.iconURL {
                    let size = 24;
                    
                    let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size))
                    KingfisherManager.shared.retrieveImage(with: url, options: [
                        .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                        .processor(processor),
                        .scaleFactor(UIScreen.main.scale),
                        .transition(.fade(1)),
                        .cacheOriginalImage
                    ]) { result in
                        switch result {
                        case .success(let value):
                            image = value.image.aspectResize(to: CGSize(width: size, height: size));
                        case .failure(_):
                            image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: globalContainerScheme().colorScheme.primaryColor);
                        }
                    }
                }
                
                self.startStraightLineNavigation(feedItem.coordinate, image: image);
            }));
            ObservationActionHandler.getDirections(latitude: feedItem.coordinate.latitude, longitude: feedItem.coordinate.longitude, title: feedItem.title ?? "Feed item", viewController: self.navigationController, extraActions: extraActions, sourceView: nil);
        });
    }
    
    func viewFeedItem(feedItem: FeedItem) {
        self.resetEnlargedPin();
        self.mageBottomSheet.dismiss(animated: true, completion: {
            self.mapCalloutDelegate.calloutTapped(feedItem);
        })
    }
    
    func copyLocation(_ location: String) {
        UIPasteboard.general.string = location;
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location copied to clipboard"))
    }
}
