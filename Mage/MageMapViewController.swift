//
//  MageMapViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 2/10/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

class MageMapViewController: MageNavStack {
    var mapView: MainMageMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = MainMageMapView(viewController: self, navigationController: self.navigationController, scheme: scheme, router: router)
        view.addSubview(mapView!)
        mapView?.autoPinEdgesToSuperviewEdges()
        NotificationCenter.default.addObserver(forName: .ObservationFiltersChanged, object:nil, queue: .main) { [weak self] notification in
            self?.setNavBarTitle()
        }

        NotificationCenter.default.addObserver(forName: .LocationFiltersChanged, object:nil, queue: .main) { [weak self] notification in
            self?.setNavBarTitle()
        }

        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setNavBarTitle()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
        setNavBarTitle()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    deinit {
        mapView = nil
    }

    func setupNavigationBar() {
        let filterButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filterTapped(_:)))
        navigationItem.rightBarButtonItems = [filterButton]
    }

    func setNavBarTitle() {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return }
        guard let event = Event.getCurrentEvent(context: context) else {
            return
        }
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
        self.navigationItem.setTitle(event.name, subtitle: subtitle, scheme: scheme)
    }
    
    @objc func filterTapped(_ sender: UIBarButtonItem) {
        // Create the SwiftUI view
        let filterView = MainFilterView()

        // Wrap it in a hosting controller
        let hostingController = UIHostingController(rootView: filterView)

        // Optional: make it look similar to your existing popover
        hostingController.modalPresentationStyle = .popover
        hostingController.popoverPresentationController?.barButtonItem = sender

        // Present it
        self.present(hostingController, animated: true)
    }

    
}
