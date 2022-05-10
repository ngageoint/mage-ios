//
//  EventChooserCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 9/7/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc protocol EventChooserDelegate {
    func eventChoosen(event: Event)
}

@objc class EventChooserCoordinator: NSObject {
    var eventDataSource: EventTableDataSource?
    var delegate: EventChooserDelegate?
    var eventController: EventChooserController?
    var viewController: UINavigationController?
    var eventToSegueTo: Event?
    var scheme: MDCContainerScheming?
    var mageEventsFetchedObserver: Any?
    
    @objc init(viewController: UINavigationController, delegate: EventChooserDelegate?, scheme: MDCContainerScheming) {
        self.viewController = viewController
        self.delegate = delegate
        self.scheme = scheme
    }
    
    @objc func start() {
        if let currentEventId = Server.currentEventId() {
            if let event = Event.getEvent(eventId: currentEventId, context: NSManagedObjectContext.mr_default()) {
                eventToSegueTo = event
                eventController?.dismiss(animated: false)
                delegate?.eventChoosen(event: event)
                if let mageEventsFetchedObserver = mageEventsFetchedObserver {
                    NotificationCenter.default.removeObserver(mageEventsFetchedObserver, name: .MAGEEventsFetched, object: nil)
                }
                return
            } else {
                Server.removeCurrentEventId()
            }
        }
        
        self.mageEventsFetchedObserver = NotificationCenter.default.addObserver(forName: .MAGEEventsFetched, object: nil, queue: .main, using: { [weak self] notification in
            self?.eventsFetched()
        })
            
        eventController = EventChooserController(delegate: self, scheme: scheme)
        viewController?.isNavigationBarHidden = false
        
        if let view = viewController?.view {
            FadeTransitionSegue.addFadeTransition(to: view)
        }
        
        if let eventController = eventController {
            viewController?.pushViewController(eventController, animated: false)
        }
        Mage.singleton.fetchEvents()
    }

    func eventsFetched() {
        eventController?.eventsFetchedFromServer()
    }
}

extension EventChooserCoordinator : EventSelectionDelegate {
    func didSelectEvent(event: Event) {
        eventToSegueTo = event
        if let remoteId = event.remoteId {
            Server.setCurrentEventId(remoteId)
        }
        MagicalRecord.save { localContext in
            // Save this event as the most recent one
            // this will get changed once it re-pulls form the server but that is fine
            let localEvent = event.mr_(in: localContext)
            localEvent?.recentSortOrder = -1
        } completion: { [weak self] didSave, error in
            self?.viewController?.isNavigationBarHidden = true
            self?.eventController?.dismiss(animated: false, completion: {
                if let eventToSegueTo = self?.eventToSegueTo {
                    self?.delegate?.eventChoosen(event: eventToSegueTo)
                }
            })
        }
    }
    
    func actionButtonTapped() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.logout()
        }
    }
}
