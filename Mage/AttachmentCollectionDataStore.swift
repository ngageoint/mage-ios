//
//  AttachmentCollectionDataStore.swift
//  MAGE
//
//  Created by Daniel Barela on 8/5/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//


import Foundation
import UIKit
import MaterialComponents
import Persistence

final class AttachmentCollectionDataStore: NSObject {

    weak var attachmentCollection: UICollectionView?

    var attachments: [Attachment] = []
    var unsentAttachments: [[String: AnyHashable]] = []

    weak var attachmentSelectionDelegate: AttachmentSelectionDelegate?
    weak var containerScheme: MDCContainerScheming?

    var attachmentFormatName: String?

    private let imageName: String?
    private let useErrorColor: Bool

    init(buttonImage imageName: String? = nil, useErrorColor: Bool = false) {
        self.imageName = imageName
        self.useErrorColor = useErrorColor
        super.init()
    }

    func applyTheme(with containerScheme: MDCContainerScheming) {
        self.containerScheme = containerScheme
        attachmentCollection?.reloadData()
    }

    private var filteredAttachments: [Attachment] {
        attachments.filter { !$0.markedForDeletion }
    }

    private var filteredUnsentAttachments: [[String: AnyHashable]] {
        unsentAttachments.filter {
            !($0["markedForDeletion"] as? Bool ?? false)
        }
    }

    private func attachment(at index: Int) -> Attachment? {
        filteredAttachments.indices.contains(index)
            ? filteredAttachments[index]
            : nil
    }

    private func unsentAttachment(at index: Int) -> [String: AnyHashable] {
        filteredUnsentAttachments[index - filteredAttachments.count]
    }

    @objc
    private func attachmentFabTapped(_ sender: MDCFloatingButton) {
        guard let delegate = attachmentSelectionDelegate else {
            return
        }

        if let attachment = attachment(at: sender.tag) {
            delegate.attachmentFabTapped(attachment) { _ in }
        } else {
            delegate.attachmentFabTappedField(unsentAttachment(at: sender.tag)) { _ in }
        }
    }
}

extension AttachmentCollectionDataStore: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        let count = filteredAttachments.count + filteredUnsentAttachments.count

        if let surfaceColor = containerScheme?.colorScheme.surfaceColor {
            collectionView.backgroundColor = count == 0 ? .clear : surfaceColor
        } else {
            collectionView.backgroundColor = count == 0 ? .clear : nil
        }

        return count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "AttachmentCell",
            for: indexPath
        ) as? AttachmentCell else {
            fatalError("Expected AttachmentCell")
        }

        var button: MDCFloatingButton?

        if let imageName {
            let fab = MDCFloatingButton(shape: .mini)

            if let image = UIImage(systemName: imageName) {
                fab.setImage(image, for: .normal)
            } else if let image = UIImage(named: imageName) {
                fab.setImage(image, for: .normal)
            }

            if useErrorColor {
                fab.applySecondaryTheme(withScheme: MAGEErrorScheme.scheme())
            } else if let containerScheme {
                fab.applySecondaryTheme(withScheme: containerScheme)
            }

            fab.tag = indexPath.item
            fab.addTarget(
                self,
                action: #selector(attachmentFabTapped(_:)),
                for: .touchUpInside
            )

            button = fab
        }

        if let attachment = attachment(at: indexPath.item) {
            cell.setImage(
                attachment: attachment,
                formatName: (attachmentFormatName ?? "") as NSString,
                button: button,
                scheme: containerScheme
            )
        } else {
            cell.setImage(
                newAttachment: unsentAttachment(at: indexPath.item),
                button: button,
                scheme: containerScheme
            )
        }

        return cell
    }
}

extension AttachmentCollectionDataStore: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let delegate = attachmentSelectionDelegate else {
            return
        }

        if let attachment = attachment(at: indexPath.item) {
            delegate.selectedAttachment(attachment)
        } else {
            delegate.selectedUnsentAttachment(
                unsentAttachment(at: indexPath.item)
            )
        }
    }
}
