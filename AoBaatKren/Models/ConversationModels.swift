import Foundation


final class Conversation {
    
    var id:String
    var name: String
    var otherUserUid: String
    var latestMsg: LatestMessage
    var creation_date: Date
    
    init(id: String, name: String, otherUserUid: String, latestMsg: LatestMessage,creation_date:Date ) {
        self.id = id
        self.name = name
        self.otherUserUid = otherUserUid
        self.latestMsg = latestMsg
        self.creation_date = creation_date
    }
}



final class LatestMessage{
    
    var date: String
    var text: String
    var isRead: Bool
    
    init(date: String, text: String, isRead: Bool) {
        self.date = date
        self.text = text
        self.isRead = isRead
    }
}
