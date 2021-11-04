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
    
    func favoriteObservation(_ observation: Observation, completion: ((Observation?) -> Void)?) {
        observation.toggleFavorite { (_, _) in
            self.mageBottomSheet.currentBottomSheetView?.refresh();
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            completion?(observation)
        }
    }
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView? = nil) {
        self.resetEnlargedPin();
        self.mageBottomSheet.dismiss(animated: true, completion: {
            guard let location = observation.location else {
                return;
            }
            var extraActions: [UIAlertAction] = [];
            extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
                self.observationToNavigateTo = observation;
                self.locationToNavigateTo = kCLLocationCoordinate2DInvalid;
                self.userToNavigateTo = nil;
                self.feedItemToNavigateTo = nil;
                self.startStraightLineNavigation(location.coordinate, image: ObservationImage.image(for: observation));
            }));
            ObservationActionHandler.getDirections(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, title: observation.primaryFeedFieldText ?? "Observation", viewController: self.navigationController, extraActions: extraActions, sourceView: nil);
        });
    }
}
