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
    
    init(url: URL) {
        self.url = url
    }
    
    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if (!DataConnectionUtilities.shouldFetchAttachments()) {
                let rect = CGRect(origin: .zero, size: CGSize(width:150, height:150))
                UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
                UIColor.init(white: 0, alpha: 0.06).setFill();
                UIRectFill(rect)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return handler(.success(Data.init((image?.cgImage?.png)!)));
            }
            let token: String = StoredPassword.retrieveStoredToken();
        
            var urlComponents: URLComponents? = URLComponents(url: self.url, resolvingAgainstBaseURL: false);
            urlComponents?.queryItems?.append(URLQueryItem(name: "access_token", value: token));
            let realUrl: URL = (urlComponents?.url)!;
            let asset: AVURLAsset = AVURLAsset(url: realUrl);
            let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset);
            generator.appliesPreferredTrackTransform = true;
            
            let time: CMTime = CMTimeMakeWithSeconds(0, preferredTimescale: 30);
            do {
                let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
                let data: Data = imageRef.png!;

                handler(.success(data))
            } catch let error as NSError {
                print("\(error.description).")
                handler(.failure(error));
            }
        }
    }
}
