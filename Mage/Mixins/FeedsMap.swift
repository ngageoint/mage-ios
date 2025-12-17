//
//  FeedsMap.swift
//  MAGE
//
//  Created by Daniel Barela on 2/9/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MapFramework
import Combine

protocol FeedsMap {
    var mapView: MKMapView? { get set }
    var scheme: MDCContainerScheming? { get set }
    var feedsMapMixin: FeedsMapMixin? { get set }
}

class FeedsMapMixin: NSObject, MapMixin {
    var feedsMap: FeedsMap
    let FEEDITEM_ANNOTATION_VIEW_REUSE_ID = "FEEDITEM_ANNOTATION"
    
    var mapAnnotationFocusedObserver: AnyObject?

    var feedItemRetrievers: [String:FeedItemRetriever] = [:]
    var currentFeeds: [String] = []
    
    var userDefaultsEventName: String?
    
    var cancellable: Set<AnyCancellable> = Set()
    
    init(feedsMap: FeedsMap) {
        self.feedsMap = feedsMap
        feedsMap.mapView?.register(MKAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: FEEDITEM_ANNOTATION_VIEW_REUSE_ID)

    }
    
    func cleanupMixin() {
        feedItemRetrievers.removeAll()
        if let mapAnnotationFocusedObserver = mapAnnotationFocusedObserver {
            NotificationCenter.default.removeObserver(mapAnnotationFocusedObserver, name: .MapAnnotationFocused, object: nil)
        }
        mapAnnotationFocusedObserver = nil
        if let userDefaultsEventName = userDefaultsEventName {
            UserDefaults.standard.removeObserver(self, forKeyPath: userDefaultsEventName)
        }
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {}

    func updateMixin(mapView: MKMapView, mapState: MapState) {}

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        NotificationCenter.default.publisher(for: .feedItemsUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.addFeeds()
            }
            .store(in: &cancellable)
        addFeeds()
    }
    
    func addFeeds() {
        guard let currentEventId = Server.currentEventId() else {
            return
        }
        
        let feedIdsInEvent = UserDefaults.standard.currentEventSelectedFeeds
        // If nothing changed, skip work
        if feedIdsInEvent == currentFeeds { return }
        // remove any feeds that are no longer selected
        let removeFeeds = currentFeeds.filter { feedId in
            return !feedIdsInEvent.contains(feedId)
        }
        // current feeds is now any that used to be selected but not any more
        for feedId in removeFeeds {
            feedItemRetrievers.removeValue(forKey: feedId)
            // Collect IDs to remove from Core Data if available
            // TODO: in some instances the CoreData feed items are getting deleted before we can perform this step. Logic in Feed and FeedsMap needs to be moved together where possible
            let itemIDsToRemove: [String] = FeedItem.getFeedItems(feedId: feedId, eventId: currentEventId.intValue)?.map { $0.id } ?? []
            // Fallback to previously stored IDs if Core Data didn't return items
            let fallbackRemoteIDs: [String] = itemIDsToRemove.isEmpty ? UserDefaults.standard.feedItemsToRemove : []
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let mapView = self.feedsMap.mapView else { return }
                
                if !itemIDsToRemove.isEmpty {
                    let annotationsToRemove = mapView.annotations.compactMap { $0 as? FeedItemAnnotation }.filter { itemIDsToRemove.contains($0.id) }
                    mapView.removeAnnotations(annotationsToRemove)
                } else if !fallbackRemoteIDs.isEmpty {
                    let annotationsToRemove = mapView.annotations.compactMap { $0 as? FeedItemAnnotation }.filter { fallbackRemoteIDs.contains($0.remoteId ?? "") }
                    mapView.removeAnnotations(annotationsToRemove)
                    UserDefaults.standard.feedItemsToRemove.removeAll()
                }
            }
        }
        
        for feedId in feedIdsInEvent {
            // This feed already is on the map
            let alreadyAdded = currentFeeds.contains { currentFeedId in
                return currentFeedId == feedId
            }
            if alreadyAdded {
                continue
            }
            guard let retriever = feedItemRetrievers[feedId] ?? {
                return FeedItemRetriever.getMappableFeedRetriever(feedId: feedId, eventId: currentEventId)
            }() else {
                continue
            }
            feedItemRetrievers[feedId] = retriever
            if let items = retriever.startRetriever() {
                if items.count == 0 {
                    if let items = retriever.startRetriever() {
                        for item in items {
                            self.feedsMap.mapView?.addAnnotation(item)
                        }
                    }
                } else {
                    for item in items {
                        feedsMap.mapView?.addAnnotation(item)
                    }
                }
            }
        }
        currentFeeds.removeAll()
        currentFeeds.append(contentsOf: feedIdsInEvent)
    }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let annotation = annotation as? FeedItemAnnotation else {
            return nil
        }

        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: FEEDITEM_ANNOTATION_VIEW_REUSE_ID) ?? {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: FEEDITEM_ANNOTATION_VIEW_REUSE_ID)
            annotationView.canShowCallout = false
            annotationView.isEnabled = false
            annotationView.isUserInteractionEnabled = false
            return annotationView
        }()
        
        FeedItemRetriever.setAnnotationImage(feedItem: annotation, annotationView: annotationView)
        annotationView.annotation = annotation
        annotationView.accessibilityLabel = "FeedItem \(annotation.id)"
        return annotationView
    }
}
