//
//  AttachmentRepository.swift
//  MAGE
//
//  Created by Dan Barela on 7/31/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import Kingfisher

private struct AttachmentRepositoryProviderKey: InjectionKey {
    static var currentValue: AttachmentRepository = AttachmentRepository()
}

extension InjectedValues {
    var attachmentRepository: AttachmentRepository {
        get { Self[AttachmentRepositoryProviderKey.self] }
        set { Self[AttachmentRepositoryProviderKey.self] = newValue }
    }
}

class AttachmentRepository: ObservableObject {
    @Injected(\.attachmentLocalDataSource)
    var localDataSource: AttachmentLocalDataSource
    
    func getAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) async -> [AttachmentModel]? {
        await localDataSource.getAttachments(
            observationUri: observationUri,
            observationFormId: observationFormId,
            fieldName: fieldName
        )
    }
    
    func observeAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) -> AnyPublisher<CollectionDifference<AttachmentModel>, Never>? {
        localDataSource.observeAttachments(observationUri: observationUri, observationFormId: observationFormId, fieldName: fieldName)
    }
    
    func getAttachment(attachmentUri: URL?) async -> AttachmentModel? {
        await localDataSource.getAttachment(attachmentUri: attachmentUri)
    }
    
    func saveLocalPath(attachmentUri: URL?, localPath: String) {
        localDataSource.saveLocalPath(attachmentUri: attachmentUri, localPath: localPath)
    }
    
    func markForDeletion(attachmentUri: URL?) {
        localDataSource.markForDeletion(attachmentUri: attachmentUri)
    }
    
    func undelete(attachmentUri: URL?) {
        localDataSource.undelete(attachmentUri: attachmentUri)
    }
    
    func appendAttachmentViewRoute(router: MageRouter, attachment: AttachmentModel) {
        var route: (any Hashable)?
        guard let contentType = attachment.contentType else {
            return
        }
        
        if contentType.hasPrefix("image") {
            if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
                route = FileRoute.showFileImage(filePath: localPath)
            } else if let urlString = attachment.url,
                      let url = URL(string: urlString)
            {
                if ImageCache.default.isCached(forKey: urlString) {
                    route = FileRoute.showCachedImage(cacheKey: urlString)
                } else if DataConnectionUtilities.shouldFetchAttachments() {
                    route = FileRoute.cacheImage(url: url)
                } else {
                    route = FileRoute.askToCache(url: url)
                }
            }
        }
        
        if let route = route {
            router.path.append(route)
        }
    }
    
    //            } else if contentType.hasPrefix("video") {
    ////                self.playAudioVideo();
    //            } else if contentType.hasPrefix("audio") {
    ////                self.playAudioVideo();
    //            } else {
    ////                var url: URL?
    ////                if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
    ////                    url = URL(fileURLWithPath: localPath)
    ////                } else if let attachmentUrl = attachment.url {
    ////                    if let attachmentUrl = URL(string: attachmentUrl) {
    ////                        let token: String = StoredPassword.retrieveStoredToken()
    ////
    ////                        var urlComponents: URLComponents? = URLComponents(url: attachmentUrl, resolvingAgainstBaseURL: false);
    ////                        if (urlComponents?.queryItems) != nil {
    ////                            urlComponents?.queryItems?.append(URLQueryItem(name: "access_token", value: token));
    ////                        } else {
    ////                            urlComponents?.queryItems = [URLQueryItem(name:"access_token", value:token)];
    ////                        }
    ////                        url = (urlComponents?.url)!;
    ////                    }
    ////                }
    ////                if let url = url {
    ////                    mediaPreviewController = MediaPreviewController(fileName: attachment.name ?? "file", mediaTitle: attachment.name ?? "file", data: nil, url: url, mediaLoaderDelegate: self, scheme: scheme)
    ////                    self.rootViewController.pushViewController(mediaPreviewController!, animated: true)
    ////                    if UIDevice.current.userInterfaceIdiom == .pad {
    ////                        self.mediaPreviewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
    ////                    }
    ////                } else {
    ////                    MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Unable to open attachment \(attachment.name ?? "file")"))
    ////                }
    //            }
    //        }
    //        return nil
    //    }
    //
    ////    func playAudioVideo(attachment: AttachmentModel) {
    ////        var name = attachment.name ?? "file"
    ////        if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
    ////            print("Playing locally", localPath);
    ////            self.urlToLoad = URL(fileURLWithPath: localPath);
    ////        } else if let attachmentUrl = attachment.url {
    ////            print("Playing from link \(attachmentUrl)");
    ////            let token: String = StoredPassword.retrieveStoredToken();
    ////
    ////            if let url = URL(string: attachmentUrl) {
    ////                var urlComponents: URLComponents? = URLComponents(url: url, resolvingAgainstBaseURL: false);
    ////                if (urlComponents?.queryItems) != nil {
    ////                    urlComponents?.queryItems?.append(URLQueryItem(name: "access_token", value: token));
    ////                } else {
    ////                    urlComponents?.queryItems = [URLQueryItem(name:"access_token", value:token)];
    ////                }
    ////                self.urlToLoad = (urlComponents?.url)!;
    ////            }
    ////        }
    ////
    ////    }
    //
    ////    func playUrl(url: URL) {
    ////
    ////        mediaPreviewController = MediaPreviewController(fileName: name, mediaTitle: name, data: nil, url: url, mediaLoaderDelegate: self, scheme: scheme)
    ////        self.rootViewController.pushViewController(mediaPreviewController!, animated: true)
    ////        if UIDevice.current.userInterfaceIdiom == .pad {
    ////            self.mediaPreviewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
    ////        }
    ////    }
}
