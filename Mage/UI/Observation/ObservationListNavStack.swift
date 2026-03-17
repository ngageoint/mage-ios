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
    private var observationFiltersObserver: NSObjectProtocol?
    private var locationFiltersObserver: NSObjectProtocol?
    private var userDefaultsObserver: NSObjectProtocol?

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

        observationFiltersObserver = NotificationCenter.default.addObserver(
            forName: .ObservationFiltersChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setNavBarTitle()
        }

        locationFiltersObserver = NotificationCenter.default.addObserver(
            forName: .LocationFiltersChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setNavBarTitle()
        }

        userDefaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setNavBarTitle()
        }
        
        setNavBarTitle()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(launchObservationFilter(_:)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavBarTitle()
    }
    
    func setNavBarTitle() {
        let timeFilterString = TimeFilter.getObservationTimeFilterString() ?? ""
        var observationFilters: [String] = []
        if !timeFilterString.isEmpty && timeFilterString != "All" {
            observationFilters.append(timeFilterString)
        }
        if Observations.getFavoritesFilter() {
            observationFilters.append("Favorites")
        }
        if Observations.getImportantFilter() {
            observationFilters.append("Important")
        }
        let observationFilter = observationFilters.joined(separator: " & ")

        let locationTimeFilterString = TimeFilter.getLocationTimeFilterString() ?? ""
        let locationFilter = (locationTimeFilterString == "All") ? "" : locationTimeFilterString

        let subtitleComponents = [observationFilter, locationFilter].filter { !$0.isEmpty }
        let subtitle = subtitleComponents.isEmpty ? nil : subtitleComponents.joined(separator: " | ")
        self.navigationItem.setTitle("Observations", subtitle: subtitle, scheme: scheme)
    }
    
    @objc func launchObservationFilter(_ sender: UIBarButtonItem) {
        let filterView = ObservationFilterView()
        let hostingController = UIHostingController(rootView: filterView)
        navigationController?.pushViewController(hostingController, animated: true)
    }

    deinit {
        if let observationFiltersObserver {
            NotificationCenter.default.removeObserver(observationFiltersObserver)
        }
        if let locationFiltersObserver {
            NotificationCenter.default.removeObserver(locationFiltersObserver)
        }
        if let userDefaultsObserver {
            NotificationCenter.default.removeObserver(userDefaultsObserver)
        }
    }
}
