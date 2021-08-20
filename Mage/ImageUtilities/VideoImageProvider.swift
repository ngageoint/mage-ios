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
    var cacheKey: String { return url.absoluteString }
    let url: URL
    let localFile: URL?
    
    init(url: URL, localPath: String?) {
        self.url = url
        if let localPath = localPath, FileManager.default.fileExists(atPath: localPath) {
            self.localFile = URL(fileURLWithPath: localPath)
        } else {
            self.localFile = nil;
        }
    }
    
    init(url: URL) {
        self.url = url;
        self.localFile = nil;
    }
    
    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let localFile = self.localFile, FileManager.default.fileExists(atPath: localFile.path) {
                let asset: AVURLAsset = AVURLAsset(url: localFile);
                do {
                    handler(.success(try self.generateThumb(asset: asset)));
                } catch let error as NSError {
                    print("\(error.description).")
                    handler(.failure(error));
                }
                return;
            }
            
            if (!DataConnectionUtilities.shouldFetchAttachments()) {
                return handler(.failure(NSError(domain:"", code:-1, userInfo:nil)))
            }
            let token: String = StoredPassword.retrieveStoredToken();
        
            var urlComponents: URLComponents? = URLComponents(url: self.url, resolvingAgainstBaseURL: false);
            if (urlComponents?.queryItems) != nil {
                urlComponents?.queryItems?.append(URLQueryItem(name: "access_token", value: token));
            } else {
                urlComponents?.queryItems = [URLQueryItem(name:"access_token", value:token)];
            }
            let realUrl: URL = (urlComponents?.url)!;
            let asset: AVURLAsset = AVURLAsset(url: realUrl);
            do {
                handler(.success(try self.generateThumb(asset: asset)));
            } catch let error as NSError {
                print("thrown error from generate thumb for url \(realUrl) \(error.description).")
                handler(.failure(error));
            }
        }
    }
    
    func generateThumb(asset: AVURLAsset) throws -> Data {
        let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset);
        generator.appliesPreferredTrackTransform = true;
        
        let time: CMTime = CMTimeMakeWithSeconds(0, preferredTimescale: 30);
        let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
        let data: Data = imageRef.png!;
        return data;
    }
}
