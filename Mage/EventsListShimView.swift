//
//  EventsListShimView.swift
//  MAGE
//
//  Created by Brent Michalski on 10/8/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import CoreData

struct EventsListShimView: View {
    @Environment(\.managedObjectContext) private var moc
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "recentSortOrder", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ],
        animation: .default
    )
    private var allEvents: FetchedResults<Event>

    @State private var search = ""
    @State private var firstLoad = true
    let onSelect: (Event) -> Void
    
    private var recent: [Event] {
        filter(allEvents.filter { ($0.recentSortOrder?.intValue ?? Int.max) > Int.max })
    }
    
    private var other: [Event] {
        filter(allEvents.filter { ($0.recentSortOrder?.intValue ?? Int.max) == Int.max })
    }
    
    private func filter(_ items: [Event]) -> [Event] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }
        return items.filter { ($0.name ?? "").localizedCaseInsensitiveContains(q) }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text("Welcome To MAGE")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Please choose an event. The observations you create and your reported location will be part of the selected event.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [Color.blue, Color.blue.opacity(0.75)],
                                       startPoint: .top, endPoint: .bottom))
            
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $search)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal)
            
            // Lists
            List {
                Section(header: Text("My Recent Events (\(recent.count))").fontWeight(.semibold)) {
                    if recent.isEmpty {
                        Text("No recent events").foregroundStyle(.secondary)
                    } else {
                        ForEach(recent, id: \.objectID) { event in
                            Button(event.name ?? "(unnamed)") { onSelect(event) }
                        }
                    }
                }
                
                Section(header: Text("Other Events (\(other.count))").fontWeight(.semibold)) {
                    if other.isEmpty {
                        Text("No other events").foregroundStyle(.secondary)
                    } else {
                        ForEach(recent, id: \.objectID) { event in
                            Button(event.name ?? "(unnamed)") { onSelect(event) }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .onChange(of: search) { _ in /* List auto-filters */ }
        }
        .task {
            // Do a fetch on first appearance
            guard firstLoad else { return }
            firstLoad = false
            _ = Event.operationToFetchEvents(success: { _, _ in }, failure: { _, _ in })
        }
    }
}

//#Preview {
//    EventsListShimView()
//}
