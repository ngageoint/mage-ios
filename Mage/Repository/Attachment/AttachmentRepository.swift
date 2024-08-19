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
            if let localPath = attachment.localPath,
               FileManager.default.fileExists(atPath: localPath)
            {
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
        } else if contentType.hasPrefix("video") {
            if let localPath = attachment.localPath,
               FileManager.default.fileExists(atPath: localPath)
            {
                route = FileRoute.showLocalVideo(filePath: localPath)
            } else if let url = URL(string: attachment.url ?? "") {
                route = FileRoute.showRemoteVideo(url: url)
            }
        } else if contentType.hasPrefix("audio") {
            if let localPath = attachment.localPath,
               FileManager.default.fileExists(atPath: localPath)
            {
                route = FileRoute.showLocalAudio(filePath: localPath)
            } else if let url = URL(string: attachment.url ?? "") {
                route = FileRoute.showRemoteAudio(url: url)
            }
        } else {
            if let urlStr = attachment.url,
               let url = URL(string: urlStr) {
                if let localPath = attachment.localPath,
                   FileManager.default.fileExists(atPath: localPath),
                   let fileUrl = URL(string: localPath)
                {
                    route = FileRoute.showDownloadedFile(fileUrl: fileUrl, url: url)
                } else if DataConnectionUtilities.shouldFetchAttachments() {
                    route = FileRoute.downloadFile(url: url)
                } else {
                    route = FileRoute.askToDownload(url: url)
                }
            }
        }
        if let route = route {
            router.path.append(route)
        }
    }
}
