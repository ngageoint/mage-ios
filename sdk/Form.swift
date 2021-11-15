//
//  Form.m
//  mage-ios-sdk
//
//

import Foundation
import SSZipArchive

@objc public class Form: NSObject {
    
    @objc public static let MAGEFormFetched = "mil.nga.giat.mage.form.fetched";
    
    static func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }

    @objc public static func operationToPullFormIcons(eventId: NSNumber, success: (() -> Void)?, failure: ((Error) -> Void)?) -> URLSessionDownloadTask? {
        let url = "\(MageServer.baseURL().absoluteURL)/api/events/\(eventId)/form/icons.zip";
        let manager = MageSessionManager.shared();
        
        let stringPath = "\(getDocumentsDirectory())/events/icons-\(eventId).zip"
        let folderToUnzipTo = "\(getDocumentsDirectory())/events/icons-\(eventId)"
        
        do {
            guard let request = try manager?.requestSerializer.request(withMethod: "GET", urlString: url, parameters: nil) else {
                return nil;
            }
            let task = manager?.downloadTask(with: request as URLRequest, progress: nil, destination: { targetPath, response in
                return URL(fileURLWithPath: stringPath);
            }, completionHandler: { response, filePath, error in
                if let error = error {
                    NSLog("Error pulling icons and form \(error)")
                    failure?(error);
                    return;
                }
                
                NSLog("event form icon request complete")
                guard let fileString = filePath?.path else {
                    return;
                }
                let unzipped = SSZipArchive.unzipFile(atPath: fileString, toDestination: folderToUnzipTo)
                if FileManager.default.isDeletableFile(atPath: fileString) {
                    do {
                        try FileManager.default.removeItem(atPath: fileString)
                    } catch {
                        NSLog("Error removing file at path: %@", error.localizedDescription);
                    }
                }
                if unzipped {
                    success?()
                } else {
                    // TODO: make actual mage errors
                    failure?(NSError(domain: "MAGE", code: 1, userInfo: nil));
                }
            })
            
            if !FileManager.default.fileExists(atPath: stringPath) {
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: stringPath).deletingLastPathComponent(), withIntermediateDirectories: true)
                } catch {
                    NSLog("Error creating directory for icons \(error)")
                }
            }
            
            return task;
        } catch {
            NSLog("Exception creating request \(error)")
        }
        return nil;
    }
}
