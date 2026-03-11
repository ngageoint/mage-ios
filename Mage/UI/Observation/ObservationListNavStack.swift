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
        let controller = MageHostingController(
            rootView: ObservationList()
                .environmentObject(router)
        )
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(controller.view)
        controller.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            controller.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
        setNavBarTitle()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(launchObservationFilter(_:)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavBarTitle()
    }
    
    func setNavBarTitle() {
        let timeFilterString = TimeFilter.getObservationTimeFilterString();
        self.navigationItem.setTitle("Observations", subtitle: (timeFilterString == "All" ? nil : timeFilterString), scheme: self.scheme);
    }
    
    @objc func launchObservationFilter(_ sender: UIBarButtonItem) {
        let filterView = ObservationFilterView()
        let hostingController = UIHostingController(rootView: filterView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
}
