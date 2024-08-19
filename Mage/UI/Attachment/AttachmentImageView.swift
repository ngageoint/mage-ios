//
//  AttachmentImageView.swift
//  MAGE
//
//  Created by Dan Barela on 8/13/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Kingfisher
import MAGEStyle
import MaterialViews

class AttachmentViewModel: ObservableObject {
    @Injected(\.attachmentRepository)
    var repository: AttachmentRepository
    
    @Published
    var attachment: AttachmentModel?
    
    @Published
    var date = Date()
    
    @Published
    var attachmentServerUrl: URL?
    
    var attachmentUri: URL?
    
    init(attachmentUri: URL?) {
        self.attachmentUri = attachmentUri
        Task { [weak self] in
            let attachment = await self?.repository.getAttachment(attachmentUri: attachmentUri)
            await MainActor.run { [weak self] in
                self?.attachment = attachment
                if let urlString = attachment?.url {
                    self?.attachmentServerUrl = URL(string: "\(urlString)")
                    self?.date = Date()
                }
            }
        }
    }
}

struct AttachmentImageView: View {
    
    @ObservedObject
    var viewModel: AttachmentViewModel
    
    var body: some View {
        KFImage(viewModel.attachmentServerUrl)
            .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
            .cacheOriginalImage()
//            .draggableAndZoomable()
    }
}

class DownloadingImageViewModel: ObservableObject {
    @Published
    var error: String?
    
    @Published
    var fileUrl: URL?
    
    @Published
    var fileDate: Date = Date()
    
    @Published
    var receivedSize: Int64 = 0
    
    @Published
    var totalSize: Int64 = 0
    
    var imageUrl: URL
    var router: MageRouter
    
    init(imageUrl: URL, router: MageRouter) {
        self.imageUrl = imageUrl
        self.router = router
        
        KingfisherManager.shared.retrieveImage(
            with: imageUrl,
            options: [
                .forceRefresh,
                .cacheOriginalImage,
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
            ],
            progressBlock: { receivedSize, totalSize in
                DispatchQueue.main.async { [weak self] in
                    self?.receivedSize = receivedSize
                    self?.totalSize = totalSize
                }
            }
        ) { result in
            switch result {
            case .success(_):
                router.path.append(FileRoute.showCachedImage(cacheKey: imageUrl.absoluteString))
            case .failure(let error):
                self.error = error.localizedDescription
            }
        }
    }
}

struct DownloadingImageView: View {
    @ObservedObject
    var viewModel: DownloadingImageViewModel
    
    var bcf: ByteCountFormatter {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf
    }
    
    var body: some View {
        VStack {
            Spacer()
            if let error = viewModel.error {
                Text("Error Downloading: \(error)")
                    .foregroundColor(Color.errorColor)
                    .primaryText()
            } else {
                Text("Downloading")
                    .primaryText()
            }
            ProgressView(value: (Float(viewModel.receivedSize) / Float(viewModel.totalSize)))
                .tint(Color.primaryColor)
            Text("Downloaded \(bcf.string(fromByteCount: viewModel.receivedSize)) of \(bcf.string(fromByteCount: viewModel.totalSize))")
                .secondaryText()
            Spacer()
        }
        .padding()
        .background(Color.backgroundColor)
    }
}

import Alamofire

class DownloadingFileViewModel: ObservableObject {
    @Published
    var error: String?
    
    @Published
    var fileUrl: URL?
    
    @Published
    var fileDate: Date = Date()
    
    @Published
    var receivedSize: Int64 = 0
    
    @Published
    var totalSize: Int64 = 0
    
    var url: URL
    var router: MageRouter
    
    init(url: URL, router: MageRouter) {
        self.url = url
        self.router = router
        
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory, options: [.createIntermediateDirectories, .removePreviousFile])

        MageSession.shared.session.download(
            url,
            method: .get,
            to: destination
        ).downloadProgress(closure: { (progress) in
                self.receivedSize = progress.completedUnitCount
                self.totalSize = progress.totalUnitCount
            }).response(completionHandler: { (response) in
                // TODO: if this was an attachment, set the local path on the entity
                // but this does not seem like the right place to do that
                if let fileUrl = response.fileURL {
                    self.router.path.append(FileRoute.showDownloadedFile(fileUrl: fileUrl, url: url))
                }
            })
    }
}

struct DownloadingFileView: View {
    @ObservedObject
    var viewModel: DownloadingFileViewModel
    
    var bcf: ByteCountFormatter {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf
    }
    
    var body: some View {
        VStack {
            Spacer()
            if let error = viewModel.error {
                Text("Error Downloading: \(error)")
                    .foregroundColor(Color.errorColor)
                    .primaryText()
            } else {
                Text("Downloading")
                    .primaryText()
            }
            ProgressView(value: (Float(viewModel.receivedSize) / Float(viewModel.totalSize)))
                .tint(Color.primaryColor)
            Text("Downloaded \(bcf.string(fromByteCount: viewModel.receivedSize)) of \(bcf.string(fromByteCount: viewModel.totalSize))")
                .secondaryText()
            Spacer()
        }
        .padding()
        .background(Color.backgroundColor)
    }
}

struct AskToCacheImageView: View {
    
    @EnvironmentObject
    var router: MageRouter
    
    var imageUrl: URL
    
    var body: some View {
        VStack {
            Spacer()
            Text("Your attachment fetch settings do not allow auto downloading full size images.  Would you like to view the image?")
                .font(.body1)
                .foregroundStyle(Color.onSurfaceColor)
            Button {
                router.path.append(FileRoute.cacheImage(url: imageUrl))
            } label: {
                Text("View")
            }
            .buttonStyle(MaterialButtonStyle(type: .contained))

            Spacer()
        }
        .padding()
        .background(Color.backgroundColor)
    }
}

struct AskToDownloadFileView: View {
    
    @EnvironmentObject
    var router: MageRouter
    
    var url: URL
    
    var body: some View {
        VStack {
            Spacer()
            Text("Your attachment fetch settings do not allow auto downloading.  Would you like to download and view the file?")
                .font(.body1)
                .foregroundStyle(Color.onSurfaceColor)
            Button {
                router.path.append(FileRoute.downloadFile(url: url))
            } label: {
                Text("View")
            }
            .buttonStyle(MaterialButtonStyle(type: .contained))

            Spacer()
        }
        .padding()
        .background(Color.backgroundColor)
    }
}

import AVKit

struct VideoView: View {
    var videoUrl: URL
    
    @State var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear{
                  if player.currentItem == nil {
                        let item = AVPlayerItem(url: videoUrl)
                        player.replaceCurrentItem(with: item)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        player.play()
                    })
                }
    }
}
