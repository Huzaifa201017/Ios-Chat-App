import Foundation



/// class representing the conversation between two sepcific users
final class Conversation {
    
    var id:String                  // conversation Id
    var name: String               // name of the recipient
    var otherUserUid: String       // user id of the recipient
    var latestMsg: LatestMessage   // latest message in that conversation
    var creation_date: Date        // creation date for this conversation
    
    init(id: String, name: String, otherUserUid: String, latestMsg: LatestMessage,creation_date:Date ) {
        self.id = id
        self.name = name
        self.otherUserUid = otherUserUid
        self.latestMsg = latestMsg
        self.creation_date = creation_date
    }
    
    
}



/// this class represent the latest message for a spcific conversation
final class LatestMessage {
    
    var date: String        // date on which this message was sent
    var text: String        // text of that message
    var isRead: Bool        // boolean to show , is it read by other user yet or not
    
    init(date: String, text: String, isRead: Bool) {
        self.date = date
        self.text = text
        self.isRead = isRead
    }
}
