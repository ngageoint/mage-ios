//
//  ObservationFilterViewSwiftUI.swift
//  MAGE
//
//  Created by Daniel Benner on 9/30/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

@objc class ObservationFilterViewSwiftUI: NSObject {
    @objc static func makeViewController() -> UIViewController {
        return UIHostingController(rootView: ObservationFilterView())
    }
}

struct ObservationFilterView: View {
    var body: some View {
        VStack {
            Text("Stuff 1")
            Text("Stuff 2")
            Text("Stuff 3")
        }
    }
}
