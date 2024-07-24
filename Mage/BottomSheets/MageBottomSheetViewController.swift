//
//  MageBottomSheetViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 9/20/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import MapKit
import SwiftUI
import Combine
import SwiftUIKitView

class BottomSheetItem: NSObject {
    var item: Any
    var annotationView: MKAnnotationView?
    var actionDelegate: Any?
    
    init(item: Any, actionDelegate: Any? = nil, annotationView: MKAnnotationView? = nil) {
        self.item = item;
        self.actionDelegate = actionDelegate;
        self.annotationView = annotationView;
    }
}

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
            .sink { bottomSheetItems in
                self.bottomSheetItems = bottomSheetItems ?? []
            }
            .store(in: &cancellable)
    }
}

struct MageBottomSheet: View {
    var scheme: MDCContainerScheming?
    
    @StateObject
    var viewModel: MageBottomSheetViewModel = MageBottomSheetViewModel()
    @State private var first = true
    @State private var isBack = false
    
    var body: some View {
        VStack {
            if viewModel.count > 1 {
                PageController(count: viewModel.count, selectedItem: viewModel.selectedItem) {
                    if viewModel.selectedItem == 0 {
                        return
                    }
                    first = false
                    isBack = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        viewModel.selectedItem = max(0, viewModel.selectedItem - 1)
                    }
                } rightTap: {
                    if viewModel.selectedItem == viewModel.count - 1 {
                        return
                    }
                    first = false
                    isBack = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        viewModel.selectedItem = min(viewModel.count - 1, viewModel.selectedItem + 1)
                    }
                }
            }
            
            ScrollView(.vertical) {
                if let bottomSheetItem = viewModel.currentBottomSheetItem?.item as? ObservationMapItem {
                    ObservationLocationBottomSheet(viewModel: ObservationLocationBottomSheetViewModel(observationLocationUri: bottomSheetItem.observationLocationId))
                } else if let bottomSheetItem = viewModel.currentBottomSheetItem?.item as? User {
                    UserBottomSheet(viewModel: UserBottomSheetViewModel(userUri: bottomSheetItem.objectID.uriRepresentation()))
                } else if let bottomSheetItem = viewModel.currentBottomSheetItem?.item as? FeatureItem {
                    FeatureBottomSheet(viewModel: StaticLayerBottomSheetViewModel(featureItem: bottomSheetItem))
                } else if let bottomSheetItem = viewModel.currentBottomSheetItem?.item as? GeoPackageFeatureItem {
                    GeoPackageFeatureBottomSheet(viewModel: GeoPackageFeatureBottomSheetViewModel(featureItem: bottomSheetItem))
                } else if let bottomSheetItem = viewModel.currentBottomSheetItem?.item as? FeedItem {
                    FeedItemBottomSheet(viewModel: FeedItemBottomSheeViewModel(feedItemUri: bottomSheetItem.objectID.uriRepresentation()))
                }
            }
            .frame(maxWidth: .infinity)
            .id(viewModel.selectedItem)
            .transition(AnyTransition.asymmetric(
                insertion: first ? .identity : .move(edge: isBack ? .leading : .trailing),
                removal:
                    (viewModel.selectedItem == viewModel.count - 1) ? .move(edge: .trailing) :
                    (viewModel.selectedItem == 0) ? .move(edge: .leading) : .move(edge: isBack ? .trailing : .leading))
            )
            .animation(.default, value: self.viewModel.selectedItem)
            
            Spacer()
        }
        
    }
}
