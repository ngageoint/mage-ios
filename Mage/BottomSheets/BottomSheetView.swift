//
//  BottomSheetView.swift
//  MAGE
//
//  Created by Daniel Barela on 9/21/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

protocol BottomSheetView {
    func getHeaderColor() -> UIColor?
    func refresh()
}

extension BottomSheetView {
    func getHeaderColor() -> UIColor? {
        return .clear
    }
    
    func refresh() {}
}
