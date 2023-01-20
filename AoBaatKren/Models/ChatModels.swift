
import Foundation
import MessageKit

final class Message: MessageType {
    
    var sender: MessageKit.SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKit.MessageKind
    
    init(sender: MessageKit.SenderType, messageId: String, sentDate: Date, kind: MessageKit.MessageKind) {
        
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.kind = kind
    }
    
    
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location (_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contanct"
        case .linkPreview(_):
            return "link"
        case .custom(_):
            return "custom"
        }
        
    }
}

final class Sender: SenderType {
    
    var senderId: String
    
    var displayName: String
    
    
    
    init(senderId: String, displayName: String) {
        
        self.senderId = senderId
        self.displayName = displayName
    }
    
}

final class Media: MediaItem{
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(url: URL? = nil, image: UIImage? = nil, placeholderImage: UIImage, size: CGSize) {
        self.url = url
        self.image = image
        self.placeholderImage = placeholderImage
        self.size = size
    }
    
    
}
