//
//  AttachmentRoutingTests+Helpers.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/12/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import CoreData
import MagicalRecord
@testable import MAGE


// MARK: - In-memory Core Date for tests
final class CoreDataTestStack {
    static func setUp() {
        // in-memory story that is isoleted for each test run
        MagicalRecord.setupCoreDataStackWithInMemoryStore()
    }
    
    static func tearDown() {
        MagicalRecord.cleanUp()
    }
}

// MARK: - Builders
func makeAttachmentModel(name: String = "file",
                         contentType: String,
                         remote: URL? = nil,
                         localFile: URL? = nil) -> AttachmentModel
{
    let ctx = NSManagedObjectContext.mr_default()
    
    let att = Attachment.mr_createEntity(in: ctx)!
    att.name = name
    att.contentType = contentType
    att.url = remote?.absoluteString
    att.localPath = localFile?.path
    
    ctx.mr_saveToPersistentStoreAndWait()
    
    return AttachmentModel(attachment: att)
}


// MARK: - Temp file helper

enum Tmp {
    static func writeTempFile(name: String = UUID().uuidString,
                              bytes: [UInt8] = [0x1,0x2,0x3]) throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        try Data(bytes).write(to: url)
        return url
    }
}
