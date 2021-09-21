//
//  MapDelegateObservationActionsDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension MapDelegate : ObservationActionsDelegate {
    
    func viewObservation(_ observation: Observation) {
        self.resetEnlargedPin();
        self.mageBottomSheet.dismiss(animated: true, completion: {
            self.mapCalloutDelegate.calloutTapped(observation);
        });
    }
    
    func favoriteObservation(_ observation: Observation) {
        observation.toggleFavorite { (_, _) in
            self.mageBottomSheet.currentBottomSheetView?.refresh();
        }
    }
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView? = nil) {
        self.resetEnlargedPin();
        self.mageBottomSheet.dismiss(animated: true, completion: {
            var extraActions: [UIAlertAction] = [];
            extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
                self.observationToNavigateTo = observation;
                self.locationToNavigateTo = kCLLocationCoordinate2DInvalid;
                self.userToNavigateTo = nil;
                self.feedItemToNavigateTo = nil;
                self.startStraightLineNavigation(observation.location().coordinate, image: ObservationImage.image(for: observation));
            }));
            ObservationActionHandler.getDirections(latitude: observation.location().coordinate.latitude, longitude: observation.location().coordinate.longitude, title: observation.primaryFeedFieldText(), viewController: self.navigationController, extraActions: extraActions, sourceView: nil);
        });
    }
}
