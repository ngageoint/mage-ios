//
//  MapDelegateUserActionsDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 7/6/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension MapDelegate : UserActionsDelegate {
    
    func viewUser(_ user: User) {
        self.resetEnlargedPin();
        self.userBottomSheet.dismiss(animated: true, completion: {
            self.mapCalloutDelegate.calloutTapped(user);
        });
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }

    func getDirectionsToUser(_ user: User) {
        self.resetEnlargedPin();
        self.userBottomSheet.dismiss(animated: true, completion: {
            guard let location: CLLocationCoordinate2D = user.location?.location().coordinate else {
                return;
            }
            var extraActions: [UIAlertAction] = [];
            extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
                
                var image: UIImage? = UIImage(named: "me")
                if let safeIconUrl = user.iconUrl {
                    if (safeIconUrl.lowercased().hasPrefix("http")) {
                        let token = StoredPassword.retrieveStoredToken();
                        do {
                            try image = UIImage(data: Data(contentsOf: URL(string: "\(safeIconUrl)?access_token=\(token ?? "")")!))
                        } catch {
                            // whatever
                        }
                    } else {
                        do {
                            try image = UIImage(data: Data(contentsOf: URL(fileURLWithPath: "\(self.getDocumentsDirectory())/\(safeIconUrl)")))
                        } catch {
                            // whatever
                        }
                    }
                    let scale = image?.size.width ?? 0.0 / 37;
                    image = UIImage(cgImage: image!.cgImage!, scale: scale, orientation: image!.imageOrientation);
                }
                
                self.startStraightLineNavigation(location, image: image);
            }));
            ObservationActionHandler.getDirections(latitude: location.latitude, longitude: location.longitude, title: user.name ?? "User", viewController: self.navigationController, extraActions: extraActions);
        });
    }
}
