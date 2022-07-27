//
//  Role.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

@objc public class Role: NSManagedObject {
    
    @discardableResult
    @objc public static func insert(json: [AnyHashable : Any], context: NSManagedObjectContext) -> Role? {
        let role = Role.mr_createEntity(in: context);
        role?.update(json: json, context: context);
        return role;
    }
    
    @objc public func update(json: [AnyHashable : Any], context: NSManagedObjectContext) {
        self.remoteId = json[RoleKey.id.key] as? String
        self.permissions = json[RoleKey.permissions.key] as? [String]
    }
    
    @objc public static func operationToFetchRoles(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let baseURL = MageServer.baseURL() else {
            return nil
        }
        let url = "\(baseURL.absoluteURL)/api/roles";
        let manager = MageSessionManager.shared();
        let methodStart = Date()
        NSLog("TIMING Fetching Roles @ \(methodStart)")
        let task = manager?.get_TASK(url, parameters: nil, progress: nil, success: { task, responseObject in
            NSLog("TIMING Fetched Roles. Elapsed: \(methodStart.timeIntervalSinceNow) seconds")
            if let responseData = responseObject as? Data {
                if responseData.count == 0 {
                    print("Roles are empty");
                    success?(task, nil);
                    return;
                }
            }
            
            guard let roles = responseObject as? [[AnyHashable : Any]] else {
                success?(task, nil);
                return;
            }
            let saveStart = Date()
            NSLog("TIMING Saving Roles @ \(saveStart)")
            MagicalRecord.save { localContext in

                // Get the role ids to query
                var roleIds: [String] = [];
                for roleJson in roles {
                    if let roleId = roleJson[RoleKey.id.key] as? String {
                        roleIds.append(roleId);
                    }
                }

                let rolesMatchingIDs: [Role] = Role.mr_findAll(with: NSPredicate(format: "(\(RoleKey.remoteId.key) IN %@)", roleIds), in: localContext) as? [Role] ?? [];
                var roleIdMap: [String : Role] = [:];
                for role in rolesMatchingIDs {
                    if let remoteId = role.remoteId {
                        roleIdMap[remoteId] = role
                    }
                }
                
                for roleJson in roles {
                    // pull from query map
                    guard let roleId = roleJson[RoleKey.id.key] as? String else {
                        continue;
                    }
                    if let role = roleIdMap[roleId] {
                        // already exists in core data, lets update the object we have
                        print("Updating role in the database \(role.remoteId ?? "")");
                        role.update(json: roleJson, context: localContext);

                    } else {
                        // not in core data yet need to create a new managed object
                        print("Inserting new role into database");
                        Role.insert(json: roleJson, context: localContext)
                    }
                }
            } completion: { contextDidSave, error in
                NSLog("TIMING inserted roles. Elapsed: \(saveStart.timeIntervalSinceNow) seconds")

                if let error = error {
                    if let failure = failure {
                        failure(task, error);
                    }
                } else if let success = success {
                    success(task, nil);
                }
            }
        }, failure: { task, error in
            if let failure = failure {
                failure(task, error);
            }
        });
        return task;
    }
}
