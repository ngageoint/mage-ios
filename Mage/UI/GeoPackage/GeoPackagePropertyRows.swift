//
//  GeoPackagePropertyRows.swift
//  MAGE
//
//  Created by Dan Barela on 7/24/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import MaterialViews
import MAGEStyle

struct GeoPackagePropertyRows: View {
    var rows: [GeoPackageProperty]
    
    var body: some View {
        ForEach(rows) { property in
            VStack(alignment: .leading) {
                Text(property.name)
                    .overlineText()
                Text(property.value ?? "")
                    .propertyValueText()
            }
            .padding(.bottom, 14)
            .padding([.leading, .trailing], 8)
        }
    }
}
