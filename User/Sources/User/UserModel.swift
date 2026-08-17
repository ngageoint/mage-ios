//
//  UserModel.swift
//  User
//
//


import Foundation
import Persistence
import CoreLocation
import SimpleFeatures

public struct UserModel: Equatable, Hashable, Sendable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(remoteId)
        hasher.combine(name ?? "")
    }
    
    public static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        return lhs.userId == rhs.userId && lhs.remoteId == rhs.remoteId && lhs.name == rhs.name
    }
    
    public init(
        userId: URL? = nil,
        remoteId: String? = nil,
        name: String? = nil,
        coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid,
        email: String? = nil,
        phone: String? = nil,
        lastUpdated: Date? = nil,
        createdAt: Date? = nil,
        avatarUrl: String? = nil,
        username: String? = nil,
        timestamp: Date? = nil,
        hasEditPermissions: Bool = false,
        hasCreatePermissions: Bool = false,
        hasDeleteObservationPermissions: Bool = false,
        horizontalAccuracy: Double? = nil,
        verticalAccuracy: Double? = nil,
        altitude: CLLocationDistance? = nil,
        recentEventIds: [NSNumber]? = nil,
        iconColor: String? = nil,
        iconText: String? = nil,
        iconUrl: String? = nil,
        isActive: Bool = true,
        role: RoleModel? = nil
    ) {
        self.userId = userId
        self.remoteId = remoteId
        self.name = name
        self.coordinate = coordinate
        self.email = email
        self.phone = phone
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
        self.avatarUrl = avatarUrl
        self.username = username
        self.timestamp = timestamp
        self.hasEditPermissions = hasEditPermissions
        self.hasCreatePermissions = hasCreatePermissions
        self.hasDeleteObservationPermissions = hasDeleteObservationPermissions
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.altitude = altitude
        self.recentEventIds = recentEventIds
        self.iconColor = iconColor
        self.iconText = iconText
        self.iconUrl = iconUrl
        self.isActive = isActive
        self.role = role
    }
    
    public var userId: URL?
    public var remoteId: String?
    public var name: String?
    public var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    public var email: String?
    public var phone: String?
    public var lastUpdated: Date?
    public var createdAt: Date?
    public var avatarUrl: String?
    public var username: String?
    public var timestamp: Date?
    public var hasEditPermissions: Bool = false
    public var hasCreatePermissions: Bool = false
    public var hasDeleteObservationPermissions: Bool = false
    public var horizontalAccuracy: Double?
    public var verticalAccuracy: Double?
    public var altitude: CLLocationDistance?
    
    public var recentEventIds: [NSNumber]?
    
    public var iconColor: String?
    public var iconText: String?
    public var iconUrl: String?
    
    public var isActive: Bool = true
    public var role: RoleModel? = nil
    
    public var validCoordinate: CLLocationCoordinate2D? {
        CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
    }
    
    public var cacheIconUrl: String? {
        get {
            let lastUpdated = String(Int(self.lastUpdated?.timeIntervalSince1970 ?? 0))
            if let iconUrl = self.iconUrl {
                return  "\(iconUrl)?_lastUpdated=\(lastUpdated)"
            }
            return nil;
        }
    }
    
    public var cacheAvatarUrl: String? {
        get {
            let lastUpdated = String(Int(self.lastUpdated?.timeIntervalSince1970 ?? 0))
            if let avatarUrl = self.avatarUrl {
                return  "\(avatarUrl)?_lastUpdated=\(lastUpdated)"
            }
            return nil;
        }
    }
    
    public var cllocation: CLLocation? {
        guard !CLLocationCoordinate2DIsValid(coordinate) else { return nil }
        return CLLocation(
            coordinate: coordinate,
            altitude: altitude ?? 0.0,
            horizontalAccuracy: horizontalAccuracy ?? 0.0,
            verticalAccuracy: verticalAccuracy ?? 0.0,
            timestamp: timestamp ?? Date(timeIntervalSince1970: 0)
        )
    }
}

extension UserModel: CoreDataDomainModelConvertible {
    public init(from user: User) {
        var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
        var horizontalAccuracy: CLLocationAccuracy?
        var verticalAccuracy: CLLocationAccuracy?
        var altitude: CLLocationDistance?
        
        if let geometryData = user.location?.geometryData,
           let geometry = SFGeometryUtils.decodeGeometry(geometryData),
           let centroid = SFGeometryUtils.centroid(of: geometry)
        {
            coordinate = CLLocationCoordinate2D(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue)
        } else {
            coordinate = kCLLocationCoordinate2DInvalid
        }
        if let dictionary = user.location?.properties as? [String: Any] {
            horizontalAccuracy = dictionary["accuracy"] as? CLLocationAccuracy ?? 0.0
            verticalAccuracy = dictionary["accuracy"] as? CLLocationAccuracy ?? 0.0
            altitude = dictionary["altitude"] as? CLLocationDistance ?? 0.0
        }
        
        var hasDeleteObservationPermissions = false
        var roleModel: RoleModel?
        if let role = user.role
        {
            roleModel = RoleModel(from: role)
            if role.permissions?.contains(PermissionsKey.DELETE_OBSERVATION.key) == true {
                hasDeleteObservationPermissions = true
            }
        }
        
        self.init(
            userId: user.objectID.uriRepresentation(),
            remoteId: user.remoteId,
            name: user.name,
            coordinate: coordinate,
            email: user.email,
            phone: user.phone,
            lastUpdated: user.lastUpdated,
            createdAt: user.createdAt,
            avatarUrl: user.cacheAvatarUrl,
            username: user.username,
            timestamp: user.location?.timestamp,
            hasEditPermissions: user.hasEditPermission,
            hasCreatePermissions: user.hasCreatePermission,
            hasDeleteObservationPermissions: hasDeleteObservationPermissions,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            altitude: altitude,
            recentEventIds: user.recentEventIds,
            iconColor: user.iconColor,
            iconText: user.iconText,
            iconUrl: user.iconUrl,
            isActive: true,
            role: roleModel
        )
    }
}
