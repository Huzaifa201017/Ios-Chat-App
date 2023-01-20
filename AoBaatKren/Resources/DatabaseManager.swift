
import Foundation
import FirebaseFirestore
import UIKit
import MessageKit

public enum DatabaseError: Error{
    case failedToFetch
    case NoDataToFetch
    case UnknowError
}

final class DatabaseManager{
    
    static private let db = Firestore.firestore()
    
    
    static func loadUserToDb(usr: User, view:UIViewController) -> Bool{
        
        var success:Bool = true
        
        // create the user
        DatabaseManager.db.collection("users").document(usr.uid).setData(["firstname":usr.firstName , "lastname": usr.lastName]) { (error) in
            
            // if operation not successful
            
            if error != nil {
                
                // show error msg
                Utlities.displayError(result: error!.localizedDescription, view: view)
                success = false
            }
            
        }
        
        return success
    }
    
    public func getAllUsers(docId:String, completion: @escaping (Result<[User],Error>)  -> Void ) {
        
        
        DatabaseManager.db.collection("users").getDocuments {snap, err in
            
            if let _ = err{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            var userCollection = [User]()
            for doc in snap!.documents{
                if doc.documentID != docId {
                    
                    if let fName = doc.data()["firstname"] as? String {
                        userCollection.append(User(firstName: fName, lastName: doc.data()["lastname"] as! String, uid: doc.documentID))
                    }
                    
                    
                }
                
            }
            
            completion(.success(userCollection))
            
            
        }
        
        
    }
    
}

extension DatabaseManager {
    
    /*
     
     "dfsdfdsfds" {
         "messages": [
             {
             "id": String,
             "type": text, photo, video,
             "content": String,
             "date": Date(), Y
             "sender_email": string,
             "isRead": true/false,
             }
         ]
     }
     conversaiton => [
         [
             "conversation_id": "dfsdfdsfds"
             "other_user_email":
             "latest_message": => {
                 "date": Date()
                 "latest_message": "message"
                 "is_read": true/false
                 }
         ],
     ]
     */
    
    public func createNewConversation(with OtherPersonsUid: String ,msgId: String ,firstMessage: Message, otherPersonName:String , completion: @escaping (Bool) -> () ) {
        
        
        let selfSenderUid = User.Instance().uid
        let dateString = ChatViewController.dateFromatter.string(from: firstMessage.sentDate)
        
        
        
        let newConversationData: [String: Any] = [
            "id": "conversations_\(msgId)",
            "other_user_Uid": OtherPersonsUid,
            "name": otherPersonName,
            "creation_date": dateString,
            "latest_message": [
                "date": dateString,
                "message": " ",
                "is_read":false
            ]
        ]
        
        let u = User.Instance()
        
        let recipientNewConversationData: [String: Any] = [
            "id": "conversations_\(msgId)",
            "other_user_Uid": selfSenderUid,
            "name": (u.firstName + " " + u.lastName),
            "creation_date": dateString,
            "latest_message": [
                "date": dateString,
                "message": "",
                "is_read":false
            ]
        ]
        
        
        DatabaseManager.db.collection("users").document(selfSenderUid).setData(["conversations": FieldValue.arrayUnion([newConversationData]) ], merge: true) { err in
            
            if let _ = err  {
                completion(false)
                return
                
            }
            
            DatabaseManager.db.collection("users").document(OtherPersonsUid).setData(["conversations": FieldValue.arrayUnion([recipientNewConversationData]) ], merge: true) { err in
                
                if let _ = err  {
                    completion(false)
                    return
                    
                }
                
                self.sendMessage(to: "conversations_\(msgId)", otherPersonName: otherPersonName, otherPersonUid: OtherPersonsUid, message:firstMessage) { result in
                    
                    if result {
                        completion(true)
                    }else{
                        completion(false)
                        return
                    }
                }
                
            }
            
          
            
        }
        
        
    }
    
    public func getAllConversations(for uid:String , completion: @escaping (Result<[Conversation],Error>) -> ()) {
        
        DatabaseManager.db.collection("users").document(uid).addSnapshotListener ({ documentSnapshot, err in
            
           
            if let err = err{
                print("Error at Line 187: DbManager: ",err.localizedDescription)
                return
            }
            guard let document = documentSnapshot else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
           
            guard var data = document.data()?["conversations"] as? [[String:Any]] else {
                completion(.failure(DatabaseError.NoDataToFetch))
                return
            }
            data = document.data()?["conversations"] as! [[String:Any]]
       
          
            var conversation:[Conversation] = [Conversation]()
           
            for dictionary in data {
                
                guard let conversationId = dictionary["id"] as? String,
                let name = dictionary ["name"] as? String,
                let otherUserUid = dictionary["other_user_Uid"] as? String,
                let latestMessage = dictionary["latest_message"] as? [String: Any],
                let date = latestMessage["date"] as? String,
                let message = latestMessage["message"] as? String,
                let isRead = latestMessage["is_read"] as? Bool,
                let creation_date_string = dictionary ["creation_date"] as? String else {return}
                
               
                let latestMessage2 = LatestMessage(date: date, text: message, isRead: isRead)
                let creation_date = ChatViewController.dateFromatter.date(from: creation_date_string )
                
                conversation.append( Conversation(id: conversationId, name: name, otherUserUid: otherUserUid, latestMsg: latestMessage2, creation_date: creation_date!))
            }
            print("Conversations Count: DBManager: Line 221: ",conversation.count)
            if conversation.count == 0{
                completion(.failure(DatabaseError.NoDataToFetch))
            }else{
                completion(.success(conversation) )
            }
            
           
            
//            var conversation:[Conversation] = data.compactMap( { dictionary in
//
//                guard let conversationId = dictionary["id"] as? String,
//                let name = dictionary ["name"] as? String,
//                let otherUserUid = dictionary["other_user_Uid"] as? String,
//                let latestMessage = dictionary["latest_message"] as? [String: Any],
//                let date = latestMessage["date"] as? String,
//                let message = latestMessage["message"] as? String,
//                let isRead = latestMessage["is_read"] as? Bool else {return}
//
//                let latestMessage2 = LatestMessage(date: date, text: message, isRead: isRead)
//
//
//                self.getConversation(convo: Conversation(id: conversationId, name: name, otherUserUid: otherUserUid, latestMsg: latestMessage2))
//            })
            
                
        })
        
    }
   
    // get all messages
    public func getAllMessagesForConversation(with id: String , creation_date: Date ,completion: @escaping (Result<[Message],Error>) -> () ){
        
       
        DatabaseManager.db.collection("Messages").document(id).addSnapshotListener ({ documentSnapshot, err in
            guard let document = documentSnapshot else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
           
            guard var data = document.data()?["messages"] as? [[String:Any]] else {
                completion(.failure(DatabaseError.NoDataToFetch))
                return
            }
            data = document.data()?["messages"] as! [[String:Any]]

            
            var messages:[Message] = [Message]()
           
    
            for dictionary in data {
              
                guard let content = dictionary["content"] as? String,
                      let name = dictionary["name"] as? String,
                      let senderUid = dictionary["senderUid"] as? String,
                      let type = dictionary["type"] as? String,
                      let messageId = dictionary["id"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFromatter.date(from: dateString)
                    
                else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                    
                }
                
                if date >= creation_date {
                    
                    let sender = Sender(senderId: senderUid, displayName: name)
                
                    var kind: MessageKind?
                    switch type {
                    case "text":
                        kind = .text(content)
                        
                        break
                    case "photo":
                        let url = URL(string: content)
                        guard let placeholder = UIImage(systemName: "plus") else {return}
                        let media = Media(url: url, image: nil,placeholderImage:placeholder,  size: CGSize(width: 230, height: 230))
                        kind = .photo(media)
                        break
                        
                    case "video":
                        let url = URL(string: content)
                        guard let placeholder = UIImage(systemName: "plus") else {return}
                        let media = Media(url: url, image: nil,placeholderImage:placeholder,  size: CGSize(width: 230, height: 230))
                        kind = .video(media)
                        break
                    default:
                        break
                        // nothing to do
                    }
                    if let kind = kind {
                        messages.append( Message(sender: sender, messageId: messageId, sentDate: date, kind: kind))
                    }
                    
                }
                
                
               
            }
            completion(.success(messages) )
           

                
        })
 
        
    }
    
    /// sends a message with target conversation and messsage
    public func sendMessage(to conversation: String ,otherPersonName:String,otherPersonUid:String ,message:Message, completion: @escaping (Bool) -> ()) {
       
        let selfSenderUid = User.Instance().uid
        let dateString = ChatViewController.dateFromatter.string(from: message.sentDate)
        var msg = ""
        var messages: [String : Any]?
        
        
        switch message.kind{
            
        case .text( let msgText):
            msg = msgText

        case .attributedText(_):
            break
        case .photo(let mediaItem):
            if let _url = mediaItem.url{
                msg = _url.absoluteString
            }
            
            break
        case .video(let mediaItem):
            if let _url = mediaItem.url{
                msg = _url.absoluteString
            }
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        messages = [
            "content": msg,
            "date": dateString,
            "id": message.messageId,
            "isRead": false,
            "senderUid":selfSenderUid,
            "name": otherPersonName,
            "type": message.kind.messageKindString
        ]
        
        // append the message in database
        DatabaseManager.db.collection("Messages").document(conversation).setData(["messages": FieldValue.arrayUnion([messages!])], merge: true) { err in
            
            if let _ = err  {
                completion(false)
                return
                
            }
            


            // update the latest Message for the sender
            self.updateLatestMsg(uid: selfSenderUid, convo_Id: conversation, message: msg, sentDate: dateString) { result in
                if result {
                    
                    completion(true)
                    
                    // update the latest Message for the reciever
                    self.updateLatestMsg(uid: otherPersonUid, convo_Id: conversation, message: msg, sentDate: dateString) { result in
                        
                        
                        if result {
                            completion(true)
                        }else {
                            
                            
                            let user = User.Instance()
                            let selfName = user.firstName + " " + user.lastName
                            
                            let newConversationData: [String: Any] = [
                                "id": conversation,
                                "other_user_Uid": selfSenderUid,
                                "name": selfName,
                                "creation_date": dateString,
                                "latest_message": [
                                    "date": dateString,
                                    "message": msg,
                                    "is_read":false
                                ]
                            ]
                            
                            DatabaseManager.db.collection("users").document(otherPersonUid).setData(["conversations": FieldValue.arrayUnion([newConversationData]) ], merge: true) { err in
                                
                                if let _ = err  {
                                    completion(false)
                                    return
                                    
                                }else{
                                    completion(true)
                                }
                            }
                            
                            
                            
                            
                        }
                    }
                    
                }else {
                    
                    let newConversationData: [String: Any] = [
                        "id": conversation,
                        "other_user_Uid": otherPersonUid,
                        "name": otherPersonName,
                        "creation_date": dateString,
                        "latest_message": [
                            "date": dateString,
                            "message": msg,
                            "is_read":false
                        ]
                    ]
                    
                    DatabaseManager.db.collection("users").document(selfSenderUid).setData(["conversations": FieldValue.arrayUnion([newConversationData]) ], merge: true) { err in
                        
                        if let _ = err  {
                            completion(false)
                            return
                            
                        }else{
                            completion(true)
                            
                            // update the latest Message for the reciever
                            self.updateLatestMsg(uid: otherPersonUid, convo_Id: conversation, message: msg, sentDate: dateString) { result in
                                if result {
                                    completion(true)
                                }else{
                                    completion(false)
                                    return
                                }
                            }
                        }
                    }
                }
            }
            
        

           
            
        }
        
    }
    func updateLatestMsg(uid: String, convo_Id: String, message:String, sentDate: String ,completion: @escaping (Bool) -> ()) {
        
        DatabaseManager.db.collection("users").document(uid).getDocument(completion: { documentSnapshot, err in
            if let err = err {
                print("Error at Line 489: DbManager: ",err.localizedDescription)
                return
            }
            
            guard let document = documentSnapshot else {
                completion(false)
                return
            }
           
            guard var data = document.data()?["conversations"] as? [[String:Any]] else {
                completion(false)
                return
            }
            data = document.data()?["conversations"] as! [[String:Any]]
       
    
            var count = 0
            var isFound = false
            for dictionary in data {
                
                if let conversationId = dictionary["id"] as? String  ,conversationId == convo_Id {
                    isFound = true
                   break
                }
                count += 1
            }
            
            if (isFound) {
                data[count]["latest_message"] = [
                    "date": sentDate,
                    "is_read": false,
                    "message": message
                ]
            
                DatabaseManager.db.collection("users").document(uid).setData([
                    "conversations": data
                ], merge: true)
                completion(true)
            }else{
                completion(false)
            }
           
        })
        
    }
    
    
    public func getUserName(uid: String , completion: @escaping (Result<Any,Error>) -> ()){
        
        Self.db.collection("users").document(uid).getDocument { documentSnapshot, err in
            
            if let err = err{
                print("Error at Line 541: DbManager: ",err)
            }
            guard let document = documentSnapshot else {
                print("Error at Line 544: DbManager: ","occured while fetching names from db")
                return
            }
            
    
            if let doc = document.data(){
               
                
                completion(.success(doc))
               
               
                
            }else {
                completion(.failure(DatabaseError.failedToFetch))
                print("Error at Line 558: DbManager: ","occured while fetching names from db")
            }
        }
        
    
    }
    
    func deleteConversation(for userId: String , recieverID: String,convoId: String, completion: @escaping (Bool) -> ()){
        
        DatabaseManager.db.collection("users").document(userId).getDocument(completion: { documentSnapshot, err in
            if let err = err {
                completion(false)
                print("Error at Line 570: DbManager: ",err.localizedDescription)
                return
            }
            
            guard let document = documentSnapshot else {
                completion(false)
                print("Error at Line 576: DbManager: ","while deleting conversation")
                return
            }
           
            guard var data = document.data()?["conversations"] as? [[String:Any]] else {
                completion(false)
                print("Error at Line 582: DbManager: ","while deleting conversation")
                return
            }
            data = document.data()?["conversations"] as! [[String:Any]]
       
    
            var count = 0
            for dictionary in data {
                
                if let conversationId = dictionary["id"] as? String  ,conversationId == convoId {
                   break
                }
                count += 1
            }
            
            data.remove(at: count)
        
            DatabaseManager.db.collection("users").document(userId).setData([
                "conversations": data
            ], merge: true)
            
            
            
            // checking if the reciever is currently accessing this conversation or not
            self.checkIfYourChatStillExists(recieverUid: recieverID, senderUid: userId) { result in
                
                switch result {
                    
                case .failure(_):
                    // if doesn't then delete the whole conversation
                    DatabaseManager.db.collection("Messages").document(convoId).delete { err in
                        if let err = err{
                            print("Error at line 614 DbManager:", err.localizedDescription)
                        }
                    }
                    break
                default:
                    break
                    
                    
                }
                
            }
            
            completion(true)
            print("Success in deleting conversation")
        })
    }
    
    
    
    func checkIfYourChatStillExists(recieverUid: String,senderUid: String,completion: @escaping (Result<String,Error>) -> () ){
        
        
        DatabaseManager.db.collection("users").document(recieverUid).getDocument(completion: { documentSnapshot, err in
            if let err = err {
                completion(.failure(DatabaseError.UnknowError))
                print("Error at Line 615: DbManager: ",err.localizedDescription)
                return
            }
            
            guard let document = documentSnapshot else {
                completion(.failure(DatabaseError.failedToFetch))
               
                return
            }
           
            guard var data = document.data()?["conversations"] as? [[String:Any]] else {
                completion(.failure(DatabaseError.UnknowError))
             
                return
            }
            data = document.data()?["conversations"] as! [[String:Any]]
       
    
            var conversationId:String?
            for dictionary in data {
                
                if let otherUSerId = dictionary["other_user_Uid"] as? String  ,otherUSerId == senderUid {
                    if let c = dictionary["id"] as? String {
                        conversationId = c
                    }
                   
                   break
                }
            
            }
            
            
        
            guard let convo = conversationId else {
                completion(.failure(DatabaseError.UnknowError))
                return
                
            }
            completion(.success(convo))
            
        })
    }
}





