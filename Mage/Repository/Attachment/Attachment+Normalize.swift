//
//  Attachment+Normalize.swift
//  MAGE
//
//  Created by Brent Michalski on 8/8/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

//import Foundation
//import CoreData
//
//extension AttachmentModel {
//    func normalizeLocalPathIfNeeded() {
//        guard
//            let healed = AttachmentPathResolver.resolve(self.localPath, fileName: self.name)
//        else { return }
//
//        let healedDir = healed.deletingLastPathComponent().path
//        guard healedDir != self.localPath else { return }
//
//        if let ctx = self.managedObjectContext {
//            ctx.perform {
//                self.localPath = healedDir
//                do { try ctx.save() } catch {
//                    NSLog("Failed to persist healed localPath: \(error)")
//                }
//            }
//        } else {
//            self.localPath = healedDir
//        }
//    }
//}
//
