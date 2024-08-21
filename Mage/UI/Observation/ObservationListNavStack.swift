//
//  ObservationListNavStack.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

class ObservationListNavStack: MageNavStack {
    override func viewDidLoad() {
        super.viewDidLoad()
        let svc = SwiftUIViewController(
            swiftUIView: ObservationList()
                .environmentObject(router)
        )
        self.view.addSubview(svc.view)
        setNavBarTitle()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(launchObservationFilter))
    }
    
    func setNavBarTitle() {
        let timeFilterString = MageFilter.getString();
        self.navigationItem.setTitle("Observations", subtitle: (timeFilterString == "All" ? nil : timeFilterString), scheme: self.scheme);
    }
    
    @objc func launchObservationFilter() {
        router.path.append(MageRoute.observationFilter)
    }
}
