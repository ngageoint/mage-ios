//
//  ObservationSyncStatus.swift
//  MAGE
//
//  Created by Dan Barela on 8/22/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import MaterialViews

struct ObservationSyncStatusSwiftUI: View {
    
    var hasError: Bool?
    var isDirty: Bool?
    var errorMessage: String?
    var pushedDate: Date?
    var syncing: Bool?
    var syncNow: ObservationActions
    
    var body: some View {
        Group {
            if !(isDirty ?? false), !(hasError ?? false), let pushedDate = pushedDate {
                successfulPush(pushedDate: pushedDate)
            } else if (hasError ?? false) {
                error(errorMessage: errorMessage)
            } else if (syncing ?? false) {
                syncInProgress()
            }
        }
    }
    
    // if the observation is not dirty and has no error, show the push date
    @ViewBuilder
    func successfulPush(pushedDate: Date) -> some View {
        HStack {
            Image(systemName: "checkmark")
            Text("Pushed on \((pushedDate as NSDate).formattedDisplay())")
        }
        .font(Font.overline)
        .foregroundColor(Color.favoriteColor)
        .opacity(0.6)
        .padding([.top, .bottom], 8)
    }
    
    // if the observation has an error
    @ViewBuilder
    func error(errorMessage: String?) -> some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
            VStack(alignment: .leading) {
                Text("Error Pushing Changes")
                if let errorMessage = errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .font(Font.overline)
            .frame(maxWidth: .infinity)
        }
        
        .foregroundColor(Color.errorColor)
        .opacity(0.6)
        .padding(8)
    }
    
    // If the observation is syncing
    @ViewBuilder
    func syncInProgress() -> some View {
        HStack {
            Group {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Changes Queued...")
            }
            .font(Font.overline)
            .foregroundColor(Color.onSurfaceColor)
            .opacity(0.6)
            
            Button {
                syncNow()
            } label: {
                Text("Sync Now")
            }
            .buttonStyle(MaterialButtonStyle(type: .text))
        }
    }
}
