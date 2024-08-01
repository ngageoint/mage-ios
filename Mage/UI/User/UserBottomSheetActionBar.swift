//
//  UserBottomSheetActionBar.swift
//  MAGE
//
//  Created by Dan Barela on 7/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

enum UserActions {
    case email(email: String)
    case phone(phone: String)
    
    func callAsFunction() {
        switch (self) {
            
        case .email (email: let email):
            guard let address = URL(string: "mailto:\(email)") else { return }
            UIApplication.shared.open(address)
            
        case .phone (phone: let phone):
            guard let number = URL(string: "tel:\(phone)") else { return }
            UIApplication.shared.open(number)
        }
    }
}

struct UserBottomSheetActionBar: View {
    var coordinate: CLLocationCoordinate2D?
    var email: String?
    var phone: String?
    var navigateToAction: CoordinateActions
    
    var body: some View {
        HStack(spacing: 0) {
            CoordinateButton(action: CoordinateActions.copyCoordinate(coordinate: coordinate))
            
            Spacer()
            
            if let email = email {
                EmailButton(emailAction: .email(email: email))
            }
            
            if let phone = phone {
                PhoneButton(phoneAction: .phone(phone: phone))
            }

            NavigateToButton(navigateToAction: navigateToAction)
        }
    }
}
