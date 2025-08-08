//
//  AttachmentPreviewView.swift
//  MAGE
//
//  Created by Dan Barela on 8/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import Kingfisher
import CoreMedia

struct AttachmentPreviewView: View {
    var attachment: AttachmentModel
    var onTap: () -> Void

    // Convenience: healed local URL if it exists
    private var healedLocalURL: URL? {
        resolveLocalFileURL(from: attachment.localPath, fileName: attachment.name)
    }

    // Convenience: remote URL (tokenized where needed)
    private var remoteURL: URL? {
        if attachment.contentType?.hasPrefix("video") ?? false {
            return attachment.urlWithToken
        }
        return URL(string: attachment.url ?? "")
    }

    var body: some View {
        Group {
            if attachment.contentType?.hasPrefix("image") ?? false {
                imageBody
            } else if attachment.contentType?.hasPrefix("video") ?? false {
                videoBody
            } else if attachment.contentType?.hasPrefix("audio") ?? false {
                audioBody
            } else {
                otherBody
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var imageBody: some View {
        // Prefer local thumbnail if available, else remote
        if let local = healedLocalURL {
            KFImage(local)
                .cacheOriginalImage()
                .onlyFromCache(!DataConnectionUtilities.shouldFetchAttachments())
                .placeholder { imagePlaceholder }
                .fade(duration: 0.3)
                .resizable()
                .scaledToFill()
                .onTapGesture { onTap() }
                .frame(maxWidth: .infinity, maxHeight: 150)
        } else if let remote = remoteURL {
            KFImage(remote)
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                .cacheOriginalImage()
                .onlyFromCache(!DataConnectionUtilities.shouldFetchAttachments())
                .placeholder { imagePlaceholder }
                .fade(duration: 0.3)
                .resizable()
                .scaledToFill()
                .onTapGesture { onTap() }
                .frame(maxWidth: .infinity, maxHeight: 150)
        } else {
            imagePlaceholder
                .onTapGesture { onTap() }
                .frame(maxWidth: .infinity, maxHeight: 150)
        }
    }

    @ViewBuilder
    private var videoBody: some View {
        // Use AVAsset provider; prefer local asset if we have one
        if let local = healedLocalURL {
            KFImage(
                source: .provider(
                    AVAssetImageDataProvider(
                        assetURL: local,
                        time: CMTime(seconds: 0.0, preferredTimescale: 1)
                    )
                )
            )
            .cacheOriginalImage()
            .placeholder { videoPlaceholder }
            .fade(duration: 0.3)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: 150)
            .overlay { videoOverlay }
            .onTapGesture { onTap() }
        } else if let remote = remoteURL {
            KFImage(
                source: .provider(
                    AVAssetImageDataProvider(
                        assetURL: remote,
                        time: CMTime(seconds: 0.0, preferredTimescale: 1)
                    )
                )
            )
            .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
            .cacheOriginalImage()
            .placeholder { videoPlaceholder }
            .fade(duration: 0.3)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: 150)
            .overlay { videoOverlay }
            .onTapGesture { onTap() }
        } else {
            videoPlaceholder
                .frame(maxWidth: .infinity, maxHeight: 150)
                .onTapGesture { onTap() }
        }
    }

    @ViewBuilder
    private var audioBody: some View {
        Image(systemName: "speaker.wave.2.fill")
            .symbolRenderingMode(.monochrome)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
            .onTapGesture { onTap() }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: 150)
            .background { Color.gray.opacity(0.27) }
    }

    @ViewBuilder
    private var otherBody: some View {
        Image(systemName: "paperclip")
            .symbolRenderingMode(.monochrome)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
            .onTapGesture { onTap() }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: 150)
            .background { Color.gray.opacity(0.27) }
    }

    // MARK: - Common UI bits

    private var imagePlaceholder: some View {
        Image("observations")
            .symbolRenderingMode(.monochrome)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
    }

    private var videoPlaceholder: some View {
        Image(systemName: "play.circle.fill")
            .symbolRenderingMode(.monochrome)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
            .padding(16)
    }

    private var videoOverlay: some View {
        Image(systemName: "play.circle.fill")
            .symbolRenderingMode(.monochrome)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
            .padding(16)
    }
}
