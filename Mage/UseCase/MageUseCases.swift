//
//  MageUseCases.swift
//  MAGE
//
//  Created by Dan Barela on 9/1/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum MageUseCases {
    case fetchEvents
    
    func callAsFunction() {
        switch (self) {
        case .fetchEvents:
            FetchEventsUseCase().execute()
        }
    }
}
