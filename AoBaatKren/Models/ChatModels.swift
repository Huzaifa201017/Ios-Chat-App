
import Foundation
import MessageKit



/// class representing message
final class Message: MessageType {
    
    var sender: SenderType       // sender of the message
    
    var messageId: String        // the unqiue id of that message
      
    var sentDate: Date           // sent date of that message
    
    var kind: MessageKind        // message kind i.e text , photo , video etc
    
    init(sender: SenderType, messageId: String, sentDate: Date, kind: MessageKind) {
        
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.kind = kind
    }
    
    
}

extension MessageKind {
    // a variable which will return the message kind as string to store in database
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


/// class representing Sender
final class Sender: SenderType {
    
    var senderId: String        // sender id
    
    var displayName: String     // name of the sender
    
    
    
    init(senderId: String, displayName: String) {
        
        self.senderId = senderId
        self.displayName = displayName
    }
    
}


/// class representing Media like photo video
final class Media: MediaItem{
    
    var url: URL?                      // url of the media item (firebase url)
    var image: UIImage?                // image corresponding to that media
    var placeholderImage: UIImage      // placeholder media
    var size: CGSize                   // size of the media to be diaplayed
    
    init(url: URL? = nil, image: UIImage? = nil, placeholderImage: UIImage, size: CGSize) {
        self.url = url
        self.image = image
        self.placeholderImage = placeholderImage
        self.size = size
    }
    
    
}
