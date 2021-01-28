//
//  ObservationActionHandler.swift
//  MAGE
//
//  Created by Daniel Barela on 1/28/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationActionHandler {
    
    static func getDirections(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, viewController: UIViewController) {
        let appleMapsQueryString = "daddr=\(latitude),\(longitude)&ll=\(latitude),\(longitude)&q=\(title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed);
        let appleMapsUrl = URL(string: "https://maps.apple.com/?\(appleMapsQueryString ?? "")");
        
        let googleMapsUrl = URL(string: "https://maps.google.com/?\(appleMapsQueryString ?? "")");
        
        let alert = UIAlertController(title: "Get Directions With...", message: nil, preferredStyle: .actionSheet);
        alert.addAction(UIAlertAction(title: "Apple Maps", style: .default, handler: { (action) in
            UIApplication.shared.open(appleMapsUrl!, options: [:]) { (success) in
                print("opened? \(success)")
            }
        }))
        alert.addAction(UIAlertAction(title:"Google Maps", style: .default, handler: { (action) in
            UIApplication.shared.open(googleMapsUrl!, options: [:]) { (success) in
                print("opened? \(success)")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
        viewController.present(alert, animated: true, completion: nil);
    }
    
    static func deleteObservation(observation: Observation, viewController: UIViewController, callback: ((Bool, Error?)->Void)?) {
        let alert = UIAlertController(title: "Delete Observation", message: "Are you sure you want to delete this observation?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes, Delete", style: .destructive , handler:{ (UIAlertAction) in
            observation.delete(completion: callback);
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        viewController.present(alert, animated: true, completion: nil)
    }
    
}
