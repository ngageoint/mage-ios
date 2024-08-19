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
    
    var body: some View {
        if let url = URL(string: attachment.url ?? "") {
            if (attachment.contentType?.hasPrefix("image") ?? false) {
                KFImage(
                    url
                )
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                .cacheOriginalImage()
                .onlyFromCache(DataConnectionUtilities.shouldFetchAttachments())
                .placeholder {
                    Image("observations")
                        .symbolRenderingMode(.monochrome)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                }
                .fade(duration: 0.3)
                .resizable()
                .scaledToFill()
                .onTapGesture {
                    onTap()
                }
                .frame(maxWidth: .infinity, maxHeight: 150)
            } else if (attachment.contentType?.hasPrefix("video") ?? false),
                      let url = attachment.urlWithToken
            {
                KFImage(
                    source: Source.provider(
                        AVAssetImageDataProvider(
                            assetURL: url,
                            time: CMTime(seconds: 0.0, preferredTimescale: 1)
                        )
                    )
                )
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                .cacheOriginalImage()
                .placeholder {
                    Image(systemName: "play.circle.fill")
                        .symbolRenderingMode(.monochrome)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                }
            
                .fade(duration: 0.3)
                .resizable()
                .scaledToFill()
                .overlay {
                    Image(systemName: "play.circle.fill")
                        .symbolRenderingMode(.monochrome)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                        .padding(16)
                }
                .onTapGesture {
                    onTap()
                }
                .frame(maxWidth: .infinity, maxHeight: 150)
            } else if (attachment.contentType?.hasPrefix("audio") ?? false) {
                Image(systemName: "speaker.wave.2.fill")
                    .symbolRenderingMode(.monochrome)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                    .onTapGesture {
                        onTap()
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .background {
                        Color.gray.opacity(0.27)
                    }
            } else {
                Image(systemName: "paperclip")
                    .symbolRenderingMode(.monochrome)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                    .onTapGesture {
                        onTap()
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .background {
                        Color.gray.opacity(0.27)
                    }
            }
        }
    }
}
