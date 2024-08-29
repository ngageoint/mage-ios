//
//  MageBottomSheetViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 7/24/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

class MageBottomSheetViewModel: ObservableObject {
    @Injected(\.bottomSheetRepository)
    var bottomSheetRepository: BottomSheetRepository
    
    var cancellable: Set<AnyCancellable> = Set()
    
    var count: Int {
        bottomSheetItems.count
    }
    
    @Published
    var selectedItem: Int = 0
    
    @Published
    var bottomSheetItems: [BottomSheetItem] = []
    
    var currentBottomSheetItem: BottomSheetItem? {
        if count > selectedItem {
            return bottomSheetItems[selectedItem]
        }
        return nil
    }
    
    init() {
        self.bottomSheetRepository.$bottomSheetItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bottomSheetItems in
                self?.bottomSheetItems = bottomSheetItems ?? []
            }
            .store(in: &cancellable)
    }
}
