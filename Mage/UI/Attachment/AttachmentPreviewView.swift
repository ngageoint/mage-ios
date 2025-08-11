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

    // Prefer a local file if we have it; otherwise use a remote thumb for images.
    // For list/grid cells a 512px thumb is a good balance.
    private var imageDisplayURL: URL? {
        attachment.bestDisplayURL(preferredThumbSize: 512)
    }

    // For videos we need the tokenized remote URL when local file is absent.
    private var localVideoURL: URL? { attachment.healedLocalURL }
    private var remoteVideoURL: URL? { attachment.urlWithToken }

    var body: some View {
        Group {
            if attachment.contentType?.hasPrefix("image") == true {
                imageBody
            } else if attachment.contentType?.hasPrefix("video") == true {
                videoBody
            } else if attachment.contentType?.hasPrefix("audio") == true {
                audioBody
            } else {
                otherBody
            }
        }
    }

    // MARK: - Image

    @ViewBuilder
    private var imageBody: some View {
        if let url = imageDisplayURL {
            KFImage(url)
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier) // ignored for file://, used for http(s)
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

    // MARK: - Video

    @ViewBuilder
    private var videoBody: some View {
        if let local = localVideoURL {
            KFImage(source: .provider(AVAssetImageDataProvider(
                assetURL: local,
                time: CMTime(seconds: 0, preferredTimescale: 1)
            )))
            .cacheOriginalImage()
            .placeholder { videoPlaceholder }
            .fade(duration: 0.3)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: 150)
            .overlay { videoOverlay }
            .onTapGesture { onTap() }
        } else if let remote = remoteVideoURL {
            KFImage(source: .provider(AVAssetImageDataProvider(
                assetURL: remote,
                time: CMTime(seconds: 0, preferredTimescale: 1)
            )))
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

    // MARK: - Audio / Other

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

    // MARK: - Placeholders / overlays

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
