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
    static var currentValue: AttachmentRepository = AttachmentRepositoryImpl()
}

extension InjectedValues {
    var attachmentRepository: AttachmentRepository {
        get { Self[AttachmentRepositoryProviderKey.self] }
        set { Self[AttachmentRepositoryProviderKey.self] = newValue }
    }
}

protocol AttachmentRepository {
    func getAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) async -> [AttachmentModel]?
    func observeAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) -> AnyPublisher<CollectionDifference<AttachmentModel>, Never>
    func getAttachment(attachmentUri: URL?) async -> AttachmentModel?
    func saveLocalPath(attachmentUri: URL?, localPath: String)
    func markForDeletion(attachmentUri: URL?)
    func undelete(attachmentUri: URL?)
    func appendAttachmentViewRoute(router: MageRouter, attachment: AttachmentModel)
}

class AttachmentRepositoryImpl: ObservableObject, AttachmentRepository {
    @Injected(\.attachmentLocalDataSource)
    var localDataSource: AttachmentLocalDataSource
    
    func getAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) async -> [AttachmentModel]? {
        await localDataSource.getAttachments(
            observationUri: observationUri,
            observationFormId: observationFormId,
            fieldName: fieldName
        )
    }
    
    func observeAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) -> AnyPublisher<CollectionDifference<AttachmentModel>, Never> {
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
        // 1) Prefer healed local file
        if let local = AttachmentPath.localURL(fromStored: attachment.localPath, fileName: attachment.name) {
            if attachment.isImage {
                router.appendRoute(FileRoute.showFileImage(filePath: local.path))
            } else if attachment.isVideo {
                router.appendRoute(FileRoute.showDownloadedFile(fileUrl: local, url: local))
            } else if attachment.isAudio {
                router.appendRoute(FileRoute.showDownloadedFile(fileUrl: local, url: local))
            } else {
                router.appendRoute(FileRoute.showDownloadedFile(fileUrl: local, url: local))
            }
            return
        }

        // 2) Remote fallbacks
        guard let remote = attachment.url.flatMap(URL.init(string:)) else { return }

        if attachment.isImage {
            if AttachmentRepoEnv.isCached(remote.absoluteString) {
                router.appendRoute(FileRoute.showCachedImage(cacheKey: remote.absoluteString))
            } else if AttachmentRepoEnv.fetchPolicy() {
                router.appendRoute(FileRoute.cacheImage(url: remote))
            } else {
                router.appendRoute(FileRoute.askToCache(url: remote))
            }
            return
        }

        if attachment.isVideo {
            if AttachmentRepoEnv.preferStreamingVideo() {
                // READY for future streaming UI
                router.appendRoute(FileRoute.showRemoteVideo(url: remote))
            } else if AttachmentRepoEnv.fetchPolicy() {
                router.appendRoute(FileRoute.downloadFile(url: remote))
            } else {
                router.appendRoute(FileRoute.askToDownload(url: remote))
            }
            return
        }

        if attachment.isAudio {
            if AttachmentRepoEnv.preferStreamingAudio() {
                // READY for future streaming UI
                router.appendRoute(FileRoute.showRemoteAudio(url: remote))
            } else if AttachmentRepoEnv.fetchPolicy() {
                router.appendRoute(FileRoute.downloadFile(url: remote))
            } else {
                router.appendRoute(FileRoute.askToDownload(url: remote))
            }
            return
        }

        // Other
        if AttachmentRepoEnv.fetchPolicy() {
            router.appendRoute(FileRoute.downloadFile(url: remote))
        } else {
            router.appendRoute(FileRoute.askToDownload(url: remote))
        }
    }
}
