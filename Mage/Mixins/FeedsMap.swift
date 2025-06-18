//
//  FeedsMap.swift
//  MAGE
//
//  Created by Daniel Barela on 2/9/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol FeedItemDelegate {
    func addFeedItem(_ feedItem: FeedItem)
    func removeFeedItem(_ feedItem: FeedItem)
}
protocol FeedsMap {
    var mapView: MKMapView? { get set }
    var scheme: MDCContainerScheming? { get set }
    var feedsMapMixin: FeedsMapMixin? { get set }
}

class FeedsMapMixin: NSObject, MapMixin {
    var feedsMap: FeedsMap
    let FEEDITEM_ANNOTATION_VIEW_REUSE_ID = "FEEDITEM_ANNOTATION"
    
    var mapAnnotationFocusedObserver: AnyObject?

    var enlargedFeedItem: MKAnnotationView?
    var feedItemRetrievers: [String:FeedItemRetriever] = [:]
    var currentFeeds: [String] = []
    var enlargedAnnotationView: MKAnnotationView?
    
    var userDefaultsEventName: String?
    
    init(feedsMap: FeedsMap) {
        self.feedsMap = feedsMap
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
    
    func setupMixin() {
        if let currentEventId = Server.currentEventId() {
            userDefaultsEventName = "selectedFeeds-\(currentEventId)"
            UserDefaults.standard.addObserver(self, forKeyPath: userDefaultsEventName!, options: [.new], context: nil)
        }
        mapAnnotationFocusedObserver = NotificationCenter.default.addObserver(forName: .MapAnnotationFocused, object: nil, queue: .main) { [weak self] notification in
            if let notificationObject = (notification.object as? MapAnnotationFocusedNotification), notificationObject.mapView == self?.feedsMap.mapView {
                self?.focusAnnotation(annotation: notificationObject.annotation)
            } else if notification.object == nil {
                self?.focusAnnotation(annotation: nil)
            }
        }
        addFeeds()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath?.starts(with: "selectedFeeds") == true {
            addFeeds()
        }
    }
    
    func addFeeds() {
        guard let currentEventId = Server.currentEventId() else {
            return
        }
        
        let feedIdsInEvent = UserDefaults.standard.currentEventSelectedFeeds
        // remove any feeds that are no longer selected
        currentFeeds.removeAll { feedId in
            return feedIdsInEvent.contains(feedId)
        }
        // current feeds is now any that used to be selected but not any more
        for feedId in currentFeeds {
            feedItemRetrievers.removeValue(forKey: feedId)
            if let items = FeedItem.getFeedItems(feedId: feedId, eventId: currentEventId.intValue) {
                for item in items where item.isMappable {
                    feedsMap.mapView?.removeAnnotation(item)
                }
            }
        }
        
        // clear the current feeds
        currentFeeds.removeAll()
        
        for feedId in feedIdsInEvent {
            guard let retriever = feedItemRetrievers[feedId] ?? {
                return FeedItemRetriever.getMappableFeedRetriever(feedId: feedId, eventId: currentEventId, delegate: self)
            }() else {
                continue
            }
            feedItemRetrievers[feedId] = retriever
            if let items = retriever.startRetriever() {
                for item in items where item.isMappable {
                    feedsMap.mapView?.addAnnotation(item)
                }
            }
        }
        
        currentFeeds.append(contentsOf: feedIdsInEvent)
    }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let annotation = annotation as? FeedItem else {
            return nil
        }

        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: FEEDITEM_ANNOTATION_VIEW_REUSE_ID) ?? {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: FEEDITEM_ANNOTATION_VIEW_REUSE_ID)
            annotationView.canShowCallout = false
            annotationView.isEnabled = false
            annotationView.isUserInteractionEnabled = false
            annotation.view = annotationView
            return annotationView
        }()
        
        FeedItemRetriever.setAnnotationImage(feedItem: annotation, annotationView: annotationView)
        annotationView.annotation = annotation
        annotationView.accessibilityLabel = "Feed \(annotation.feed?.remoteId ?? "") Item \(annotation.remoteId ?? "")"
        annotation.view = annotationView
        return annotationView
    }
    
    func focusAnnotation(annotation: MKAnnotation?) {
        guard let annotation = annotation as? FeedItem,
              let annotationView = annotation.view else {
                  if let enlargedAnnotationView = enlargedAnnotationView {
                      // shrink the old focused view
                      UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                          enlargedAnnotationView.transform = enlargedAnnotationView.transform.scaledBy(x: 0.5, y: 0.5)
                          enlargedAnnotationView.centerOffset = CGPoint(x: 0, y: enlargedAnnotationView.centerOffset.y / 2.0)
                      } completion: { success in
                      }
                      self.enlargedAnnotationView = nil
                  }
                  return
              }
        
        if annotationView == enlargedAnnotationView {
            // already focused ignore
            return
        } else if let enlargedAnnotationView = enlargedAnnotationView {
            // shrink the old focused view
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
                enlargedAnnotationView.transform = enlargedAnnotationView.transform.scaledBy(x: 0.5, y: 0.5)
                enlargedAnnotationView.centerOffset = CGPoint(x: 0, y: annotationView.centerOffset.y / 2.0)
            } completion: { success in
            }
        }
        
        enlargedAnnotationView = annotationView
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut) {
            annotationView.transform = annotationView.transform.scaledBy(x: 2.0, y: 2.0)
            annotationView.centerOffset = CGPoint(x: 0, y: annotationView.centerOffset.y * 2.0)
        } completion: { success in
        }
    }
}
    
extension FeedsMapMixin : FeedItemDelegate {
    func addFeedItem(_ feedItem: FeedItem) {
        if (feedItem.isMappable) {
            feedsMap.mapView?.addAnnotation(feedItem);
        }
    }
    
    func removeFeedItem(_ feedItem: FeedItem) {
        if (feedItem.isMappable) {
            feedsMap.mapView?.removeAnnotation(feedItem);
        }
    }
}
