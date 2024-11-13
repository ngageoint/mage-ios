
import Foundation
import Security

enum DeviceUUIDKeys: String {
    case attachmentPushFrequency,
         sessionIdentifier = "mil.nga.giat.mage.uuid"
}

@objc class DeviceUUID: NSObject {
    
    @objc public static func retrieveDeviceUUID() -> UUID? {
        // Failed to read the UUID from the KeyChain, so create a new UUID and store it
        if let uuidString = DeviceUUID.retrieveUUIDFromKeyChain(), !uuidString.isEmpty {
            return UUID(uuidString: uuidString)
        } else if let uuidString = DeviceUUID.persistUUIDToKeyChain() {
            return UUID(uuidString: uuidString)
        }
        return nil
    }
    
    static func retrieveUUIDFromKeyChain() -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "mil.nga.giat.mage.uuid",
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnAttributes: kCFBooleanTrue!,
            kSecReturnData: true
        ] as CFDictionary
        
        var attributesRef: CFTypeRef?
        let result = SecItemCopyMatching(query, &attributesRef)
        if result == noErr {
            // There is a UUID, so try to retrieve it
            guard let existingItem = attributesRef as? [String : Any],
                let uuidData = existingItem[kSecValueData as String] as? Data,
                let uuid = String(data: uuidData, encoding: String.Encoding.utf8)
            else {
                return nil
            }
            return uuid
        }
        return nil
    }
    
    @objc public static func persistUUIDToKeyChain() -> String? {
        // Generate the new UUID
        let uuid = UUID()
        let uuidString = uuid.uuidString
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "mil.nga.giat.mage.uuid",
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData: uuidString.data(using: .utf8)!
        ] as CFDictionary
        
        let result = SecItemAdd(query, nil)
        
        if result != noErr {
            NSLog("ERROR: Couldn't add to the Keychain. Result = \(result); Query = \(query)")
            return nil
        }
        return uuidString
    }
}
