//
//  ObservationActionHandler.swift
//  MAGE
//
//  Created by Daniel Barela on 1/28/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationActionHandler {
    
    static func getDirections(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, viewController: UIViewController, extraActions: [UIAlertAction]? = nil, sourceView: UIView? = nil) {
        let appleMapsQueryString = "daddr=\(latitude),\(longitude)&ll=\(latitude),\(longitude)&q=\(title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed);
        let appleMapsUrl = URL(string: "https://maps.apple.com/?\(appleMapsQueryString ?? "")");
        
        let googleMapsUrl = URL(string: "https://maps.google.com/?\(appleMapsQueryString ?? "")");
        
        let alert = UIAlertController(title: "Navigate With...", message: nil, preferredStyle: .actionSheet);
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
        if let extraActions = extraActions {
            for action in extraActions {
                alert.addAction(action);
            }
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
        
        if let popoverController = alert.popoverPresentationController {
            var view: UIView = viewController.view;
            if let sourceView = sourceView {
                view = sourceView;
            } else {
                popoverController.permittedArrowDirections = [];
            }
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
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
