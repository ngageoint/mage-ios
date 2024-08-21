//
//  LocationListNavStack.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

class LocationListNavStack: MageNavStack {
    override func viewDidLoad() {
        super.viewDidLoad()
        let svc = SwiftUIViewController(
            swiftUIView: LocationList()
            .environmentObject(router)
        )
        self.view.addSubview(svc.view)
        setNavBarTitle()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(launchLocationFilter))
    }
    
    func setNavBarTitle() {
        let timeFilterString = MageFilter.getLocationFilterString()
        self.navigationItem.setTitle("People", subtitle: (timeFilterString == "All" ? nil : timeFilterString), scheme: self.scheme);
    }
    
    @objc func launchLocationFilter() {
        router.path.append(MageRoute.locationFilter)
    }
}
