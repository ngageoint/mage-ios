//
//  Event.swift
//  Persistence
//
//  Created by Daniel Barela on 8/5/26.
//


import Foundation
import CoreData
import MapKit

@objc public class Event: NSManagedObject {

}

@objc public class Attachment: NSManagedObject {
    
}
@objc public class Canary: NSManagedObject {
    
}
@objc public class Feed: NSManagedObject {
    
}
@objc public class FeedItem: NSManagedObject {
    public var view: MKAnnotationView?
}
@objc public class Form: NSManagedObject {
    
}
@objc public class FormJson: NSManagedObject {
    
}
@objc public class GPSLocation: NSManagedObject {
    
}
@objc public class ImageryLayer: Layer {
    
}
@objc public class Layer: NSManagedObject {
    
}
@objc public class Location: NSManagedObject {
    
}
@objc public class Observation: NSManagedObject {
    @objc public var transientAttachments: [Attachment] = [];
    @objc public var formsToBeDeleted: NSMutableIndexSet = NSMutableIndexSet()
}
@objc public class ObservationFavorite: NSManagedObject {
    
}
@objc public class ObservationImportant: NSManagedObject {
    
}
@objc public class Role: NSManagedObject {
    
}
@objc public class Server: NSManagedObject {
    
}
@objc public class Settings: NSManagedObject {
    
}
@objc public class StaticLayer: Layer {
    
}
@objc public class Team: NSManagedObject {
    
}
@objc public class User: NSManagedObject {
    
}
