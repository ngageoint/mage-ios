//
//  VideoImageProvider.swift
//  MAGE
//
//  Created by Daniel Barela on 3/27/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//
import AVKit
import Kingfisher

extension CGImage {
    var png: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}

struct VideoImageProvider: ImageDataProvider {
    var cacheKey: String { return sourceUrl.absoluteString }
    let sourceUrl: URL
    let localUrl: URL?

    init(sourceUrl: URL, localPath: String?) {
        self.sourceUrl = sourceUrl
        self.localUrl = if let localPath { URL(fileURLWithPath: localPath) } else { nil }
    }
    
    init(url: URL) {
        self.sourceUrl = url
        self.localUrl = nil
    }
    
    init(localPath: String) {
        self.localUrl = URL(fileURLWithPath: localPath)
        self.sourceUrl = self.localUrl!
    }
    
    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let localFile = self.localUrl, FileManager.default.fileExists(atPath: localFile.path) {
                let asset: AVURLAsset = AVURLAsset(url: localFile)
                do {
                    handler(.success(try self.generateThumb(asset: asset)))
                } catch let error as NSError {
                    MageLogger.misc.error("\(error.description).")
                    handler(.failure(error))
                }
                return
            }
            
            if (!DataConnectionUtilities.shouldFetchAttachments()) {
                return handler(.failure(NSError(domain: "MAGE", code: -1, userInfo: [ NSLocalizedDescriptionKey: "attachment fetching is disabled" ])))
            }

            let realUrl = AccessTokenURL.tokenized(sourceUrl)
            let asset: AVURLAsset = AVURLAsset(url: realUrl)
            
            do {
                handler(.success(try self.generateThumb(asset: asset)))
            } catch let error as NSError {
                MageLogger.misc.error("thrown error from generate thumb for url \(realUrl) \(error.description).")
                handler(.failure(error))
            }
        }
    }
    
    func generateThumb(asset: AVURLAsset) throws -> Data {
        let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time: CMTime = CMTimeMakeWithSeconds(0, preferredTimescale: 30)
        let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
        let data: Data = imageRef.png!
        return data
    }
}
