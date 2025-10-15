//
//  EventSelectionHost.swift
//  MAGE
//
//  Created by Brent Michalski on 10/8/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import SwiftUI
import CoreData

@MainActor
final class EventSelectionHost: UIViewController {
    private let context: NSManagedObjectContext
    private let onSelect: (Event) -> Void
    
    init(context: NSManagedObjectContext, onSelect: @escaping (Event) -> Void) {
        self.context = context
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        
        let root = EventsListShimView { [weak self] event in
            self?.onSelect(event)
        }
        
        let hosting = UIHostingController(rootView: root.environment(\.managedObjectContext, context))
        embed(hosting)
    }
}



private extension UIViewController {
    func embed(_ child: UIViewController) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        child.didMove(toParent: self)
    }
}
