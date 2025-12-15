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
            .removeDuplicates()
            .sink { [weak self] notification in
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
        // remove any feeds that are no longer selected
        let removeFeeds = currentFeeds.filter { feedId in
            return !feedIdsInEvent.contains(feedId)
        }
        // current feeds is now any that used to be selected but not any more
        for feedId in removeFeeds {
            feedItemRetrievers.removeValue(forKey: feedId)
            if let items = FeedItem.getFeedItems(feedId: feedId, eventId: currentEventId.intValue) {
                for item in items {
                    if let feedAnnotation = feedsMap.mapView?.annotations.first(where: { annotation in
                        if let annotation = annotation as? FeedItemAnnotation {
                            return annotation.id == item.id
                        }
                        return false
                    }) as? FeedItemAnnotation {
                        feedsMap.mapView?.removeAnnotation(feedAnnotation); // NOTE: Toggling a Feed will trigger this...
                    }
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
                // TODO: CHECK IF FIXED WITH NOTIFICATIONS
                if items.count == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        if let items = retriever.startRetriever() {
                            for item in items {
                                self.feedsMap.mapView?.addAnnotation(item)
                            }
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
