//
//  GeoPackageMediaRow.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct GeoPackageMediaRow: Identifiable, Hashable {
    let id: String = UUID().uuidString
    
    let title: String
    let image: UIImage
}
