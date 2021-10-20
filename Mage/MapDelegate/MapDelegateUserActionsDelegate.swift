//
//  MapDelegateUserActionsDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 7/6/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

extension MapDelegate : UserActionsDelegate {
    
    func viewUser(_ user: User) {
        self.resetEnlargedPin();
        self.mageBottomSheet.dismiss(animated: true, completion: {
            self.mapCalloutDelegate.calloutTapped(user);
        });
    }

    func getDirectionsToUser(_ user: User, sourceView: UIView?) {
        self.userToNavigateTo = user;
        self.observationToNavigateTo = nil;
        self.locationToNavigateTo = kCLLocationCoordinate2DInvalid;
        self.feedItemToNavigateTo = nil;
        self.resetEnlargedPin();
        self.mageBottomSheet.dismiss(animated: true, completion: {
            guard let location: CLLocationCoordinate2D = user.location?.location().coordinate else {
                return;
            }
            var extraActions: [UIAlertAction] = [];
            extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
                
                var image: UIImage? = UIImage(named: "me")
                if let cacheIconUrl = user.cacheIconUrl {
                    let url = URL(string: cacheIconUrl)!;
                    
                    KingfisherManager.shared.retrieveImage(with: url, options: [
                        .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                        .scaleFactor(UIScreen.main.scale),
                        .transition(.fade(1)),
                        .cacheOriginalImage
                    ]) { result in
                        switch result {
                        case .success(let value):
                            let scale = value.image.size.width / 37;
                            image = UIImage(cgImage: value.image.cgImage!, scale: scale, orientation: value.image.imageOrientation);
                        case .failure(_):
                            image = UIImage.init(named: "me")?.withRenderingMode(.alwaysTemplate);
                        }
                        self.startStraightLineNavigation(location, image: image);
                    }
                } else {
                    self.startStraightLineNavigation(location, image: image);
                }
            }));
            ObservationActionHandler.getDirections(latitude: location.latitude, longitude: location.longitude, title: user.name ?? "User", viewController: self.navigationController, extraActions: extraActions, sourceView: nil);
        });
    }
}
