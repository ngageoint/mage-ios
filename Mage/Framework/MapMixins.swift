//
//  MapMixins.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class MapMixins: ObservableObject {
    @Published var mixins: [any MapMixin] = []
    func addMixin(_ mixin: any MapMixin) {
        mixins.append(mixin)
    }
}
