//
//  MapDelegateFeatureActionsDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 7/13/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension MapDelegate : FeatureActionsDelegate {
    func getDirectionsToLocation(_ location: CLLocationCoordinate2D, title: String?, sourceView: UIView?) {
        self.mageBottomSheet.dismiss(animated: true) {
            var extraActions: [UIAlertAction] = [];
            extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
                self.locationToNavigateTo = location;
                self.observationToNavigateTo = nil;
                self.userToNavigateTo = nil;
                self.feedItemToNavigateTo = nil;
                let image: UIImage? = UIImage(named: "observations")
                self.startStraightLineNavigation(location, image: image);
            }));
            ObservationActionHandler.getDirections(latitude: location.latitude, longitude: location.longitude, title: title ?? "Feature", viewController: self.navigationController, extraActions: extraActions, sourceView: nil);
        }
    }
}
