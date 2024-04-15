//
//  MapMixins.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public class MapMixins: ObservableObject {
    @Published public var mixins: [any MapMixin] = []

    public init() {

    }
    
    public func addMixin(_ mixin: any MapMixin) {
        mixins.append(mixin)
    }
}
