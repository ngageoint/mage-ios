//
//  AttachmentCell.m
//  Mage
//
//
import UIKit
import Kingfisher

@objc class AttachmentCell: UICollectionViewCell {

    @IBOutlet weak var imageView: AttachmentUIImageView?;
    
    override func prepareForReuse() {
        self.imageView?.kf.cancelDownloadTask();
        for view in (self.imageView)!.subviews{
            view.removeFromSuperview()
        }
    }

    func getAttachmentUrl(size: Int, attachment: Attachment) -> URL {
        if (attachment.localPath != nil && FileManager.default.fileExists(atPath: attachment.localPath!)) {
            return URL(fileURLWithPath: attachment.localPath!);
        } else {
            return URL(string: String(format: "%@?size=%ld", attachment.url!, size))!;
        }
    }
    
    @objc public func setImage(attachment: Attachment, formatName:NSString) {
        self.imageView?.kf.indicatorType = .activity;
        let imageSize: Int = Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale);
        if (attachment.contentType?.hasPrefix("image") ?? false) {
            self.imageView?.setAttachment(attachment: attachment);
            self.imageView?.showThumbnail();
        } else if (attachment.contentType?.hasPrefix("video") ?? false) {
            let url = self.getAttachmentUrl(size: imageSize, attachment: attachment);
            let provider: VideoImageProvider = VideoImageProvider(url: url);
            self.imageView?.kf.setImage(with: provider, placeholder: UIImage.init(named: "download_thumbnail"), options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                .transition(.fade(0.2)),
                .scaleFactor(UIScreen.main.scale),
                .processor(DownsamplingImageProcessor(size: (self.imageView?.frame.size)!)),
                .cacheOriginalImage
            ])
            { result in
                switch result {
                case .success(_):
                    let overlay: UIImageView = UIImageView(image: UIImage.init(named: "play_overlay"));
                    overlay.contentMode = .scaleAspectFit;
                    self.imageView?.addSubview(overlay);
                case .failure(let error):
                    print(error);
                    let overlay: UIImageView = UIImageView(image: UIImage.init(named: "play_overlay"));
                    overlay.contentMode = .scaleAspectFit;
                    self.imageView?.addSubview(overlay);
                }
            };
            
        } else if (attachment.contentType?.hasPrefix("audio") ?? false) {
            self.imageView?.image = UIImage.init(named: "audio_thumbnail");
        } else {
            self.imageView?.image = UIImage.init(named: "paperclip_thumbnail");
        }
    }
}
