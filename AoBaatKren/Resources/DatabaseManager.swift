import FirebaseFirestore
import UIKit
import MessageKit

public enum DatabaseError: Error{
    case failedToFetch
    case NoDataToFetch
    case UnknowError
}


final class DatabaseManager {
    
    static private let db = Firestore.firestore()
    
    // MARK: Operations regarding User data
    
    
    /// This function loads the user firstname and lastname of the current user , who just signed up
    /// - Parameters:
    ///   - usr: object of User class that should have firstname and lastname attributes values non empty
    ///   - view: view in which the function is being called
    /// - Returns: returns true if the operation was successful otherwise false.
    static func loadUserToDb(usr: User, view:UIViewController) -> Bool{
        // intitally assume the operation is successful
        var success:Bool = true
        
        // create the user
        Self.db.collection("users").document(usr.uid).setData(["firstname":usr.firstName , "lastname": usr.lastName]) { (error) in
            
            // if operation not successful
            
            if error != nil {
                
                // show error msg
                Utlities.displayError(result: error!.localizedDescription, view: view)
                success = false // operation status is false now.
            }
            
        }
        
        return success
    }
    
    
    
    
    /// get all users(which are registered on this app), from firebase firestore
    /// - Parameters:
    ///   - docId: docId stands for document ID , and it is same as the user id of the current logged in user , so it is basically the user id the current logged in user.
    ///   - completion: completion handler , wiihc returns the array of all users in case of success and return error in case of error.
    public func getAllUsers(docId:String, completion: @escaping (Result<[User],Error>)  -> Void ) {
        
        // get documents from firestore
        Self.db.collection("users").getDocuments {snap, err in
            // if there is an error in getting documents
            if let _ = err {
                // - return the error
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            // else
            // - initialize the empty array of users
            var userCollection = [User]()
            // - For all documents
            for doc in snap!.documents {
                // - those documents , the id of which is not equal to the docId i.e all users except the current logged in user , who is calling that function
                if doc.documentID != docId {
                    // - and if those documents's fieds are not empty
                    if let fName = doc.data()["firstname"] as? String {
                        // - append the user , for that document data , to the user array
                        userCollection.append( User(firstName: fName, lastName: doc.data()["lastname"] as! String, uid: doc.documentID) )
                    }
                    
                    
                }
                
            }
            // - after all the users recieved , return them
            completion(.success(userCollection))
            
            
        }
        
        
    }
    
    
    
    /// get a specific user data ( document data in terms of firestore ), from firebase firestore
    /// - Parameters:
    ///   - uid: user Id of the user of which you want to get the data
    ///   - completion: completion handler , which returns the user data on sucess and return error on failure
    public func getUserDocumentData(uid: String , completion: @escaping (Result<Any,Error>) -> ()){
        
        // get document, for the user, with id = uid
        Self.db.collection("users").document(uid).getDocument { documentSnapshot, err in
            
            // if error occurs
            if let err = err {
                // return the error
                completion(.failure(DatabaseError.failedToFetch))
                print("Error at Line 103: DbManager: ",err)
                return
            }
            // else if the document is nil
            guard let document = documentSnapshot else {
                // return the error in this case also, as nil means no document so we can consider it as an error somehow
                completion(.failure(DatabaseError.failedToFetch))
                print("Error at Line 110: DbManager: ","occured while fetching names from db")
                return
            }
            
    
            // else if the document data is fetched properly
            if let doc = document.data() {
               
                // return it
                completion(.success(doc))
               
               
                
            }
            // else
            else {
                // return the error this time too
                completion(.failure(DatabaseError.failedToFetch))
                print("Error at Line 128: DbManager: ","occured while fetching names from db")
            }
        }
        
    
    }
    
    
    
}





extension DatabaseManager {
    
    
    // MARK: Operations regarding Users Conversations data
    
    /*
     
     Messages => {
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
    
    
    /// create new conversation between two users in firestore
    /// - Parameters:
    ///   - OtherPersonsUid: the other user Id with whom you want to create a new conversation with
    ///   - msgId: the unique Id for a message i.e the message you just sent to that user
    ///   - firstMessage: the actual message you want to send , which is of 'Message' type
    ///   - otherPersonName: the name of the person you want to create a new conversation with
    ///   - completion: completion handler , that returns true on success and return false on failure
    public func createNewConversation(with OtherPersonsUid: String ,msgId: String ,firstMessage: Message, otherPersonName:String , completion: @escaping (Bool) -> () ) {
        
        
        let selfSenderUid = User.Instance().uid // user id of the sender
        // convert the message sentdata , from datatype date to string, usinf date formatter defined in ChatViewController class
        let dateString = ChatViewController.dateFromatter.string(from: firstMessage.sentDate)
        
        
        
        // data for new conversation(for sender side), which is to be loaded in firestore, where:
        // - id = unique identifier for new conversation , as same user may have multiple conversations
        // - other_user_Uid = user id of the other person you want to start a new conversation with
        // - name = name of the user you want to start a new conversation with
        // - creation_date = the date at which the conversation was being started
        // - latest_message = latest message , residing in that conversation
        // -- its message field is left empty for now , as the message can be of multiple type , so we'll handle it separately in the 'sendMessgae' function
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
        
        
        
        let u = User.Instance() // self user (i.e the sender)
        
        
        // data for new conversation(for reciever side), which is to be loaded in firestore, where:
        // - id = its value and description is same as above, as it is the same conversation
        // - other_user_Uid = same description as above but ,for reciever side obviously the the other person is actually the sender, so here the value would be the sender id
        // - name = same description as above but ,for reciever side obviously the the other person is actually the sender, so here the value would be the sender name
        // - creation_date = its value and description is same as above
        // - latest_message = its value and description is same as above
        // -- its message field is left empty for now , for the same reason as above.
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
        
        
        // create new field in the document representing the sender i.e the document with id = sender id (selfSenderUid).
        // That new field is named as conversations with the value = array of conversations.
        // arrayUnion , actually append the object if the array already exists , or if already doesnt exists it creates the new one automatically
        // so here the value for conversation would be 'newConversationData' as defined above for the sender
        DatabaseManager.db.collection("users").document(selfSenderUid).setData(["conversations": FieldValue.arrayUnion([newConversationData]) ], merge: true) { err in
            
            // if err occured , no need to fill the reciever side , just return
            if let _ = err  {
                completion(false)
                return
                
            }
            
            // else
            
            // create new field in the document representing the reciever i.e the document with id = reciever id (OtherPersonsUid).
            // That new field is named as conversations with the value = array of conversations, here also as above
            // so here the value for conversation would be 'recipientNewConversationData' as defined above for the reciever
            
            DatabaseManager.db.collection("users").document(OtherPersonsUid).setData(["conversations": FieldValue.arrayUnion([recipientNewConversationData]) ], merge: true) { err in
                
                // if err occured , no need to fill the reciever side , just return
                if let _ = err  {
                    completion(false)
                    return
                    
                }
                
                // else
                // now the conversation is created , now just send the message, where the id of the document which will store all the messages for this conversation is same as the conversation if that converation i.e "conversations_\(msgId)"
                
                self.sendMessage(to: "conversations_\(msgId)", otherPersonName: otherPersonName, otherPersonUid: OtherPersonsUid, message:firstMessage) { result in
                    
                    // if all goes well ,
                    if result {
                        // return true
                        completion(true)
                        
                    }else{
                        // return false
                        completion(false)
                        return
                    }
                }
                
            }
            
          
            
        }
        
        
    }
    
    
    
    /// get all the conversations for a particular user i.e the caller user , the one which is calling that function
    /// - Parameters:
    ///   - uid: user id of the caller user
    ///   - completion: completion handler , which returns  the array of conversations on success and return error on failure
    public func getAllConversations(for uid:String , completion: @escaping (Result<[Conversation],Error>) -> ()) {
        
        // get live conversation update , from document with document id = uid , which is residing in "users" collection.
        // addSnapshotListener is same as getdocument function , but what is does that as soon as someone changes the data(the data which you are fetching here), in firestore, may be you or some other person, this portion of code gets called again automatically , so we would have a listner function for this in some view conrtoller , which will listen live updates from that function
        DatabaseManager.db.collection("users").document(uid).addSnapshotListener ({ documentSnapshot, err in
            
            // if error occurs in fetching the data
            if let err = err {
                // return error
                completion(.failure(DatabaseError.failedToFetch))
                print("Error at Line 308: DbManager: ",err.localizedDescription)
                return
            }
            
            // if the snapshot contains nothing
            guard let document = documentSnapshot else {
                // then return error too
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            // if the document contains nothing
           
            guard let data = document.data()?["conversations"] as? [[String:Any]] else {
                // return the error
                completion(.failure(DatabaseError.NoDataToFetch))
                return
            }
            
            // else we have the data
       
            // initialize an empty array of type Conversation
            var conversation:[Conversation] = [Conversation]()
           
            // loop for the data , as wo know that "conversations" field contains data of array type
            for dictionary in data {
                // if any of the subfield of "conversations" field is empty
                guard let conversationId = dictionary["id"] as? String,
                let name = dictionary ["name"] as? String,
                let otherUserUid = dictionary["other_user_Uid"] as? String,
                let latestMessage = dictionary["latest_message"] as? [String: Any],
                let date = latestMessage["date"] as? String,
                let message = latestMessage["message"] as? String,
                let isRead = latestMessage["is_read"] as? Bool,
                let creation_date_string = dictionary ["creation_date"] as? String else {
                    // return
                    return
                    
                }
                // else , we have all the data
                // get latest message from that data
                let latestMessage2 = LatestMessage(date: date, text: message, isRead: isRead)
                // get creation date of that conversation and convert it into date format
                let creation_date = ChatViewController.dateFromatter.date(from: creation_date_string )
                // append the corresponding conversation with the above data in the array intialzed above.
                conversation.append( Conversation(id: conversationId, name: name, otherUserUid: otherUserUid, latestMsg: latestMessage2, creation_date: creation_date!))
                
                
            }
            
            print("Conversations Count: DBManager: Line 360: ",conversation.count)
            // if we  have no conversations then
            if conversation.count == 0{
                // return error this time too (yes its not an error but it would make our work simple)
                completion(.failure(DatabaseError.NoDataToFetch))
            }else {
                // else , return the conversations list , on success
                completion(.success(conversation) )
            }
            
                
        })
        
    }
    
    
    /// this function deletes a conversation for a particular user
    /// - Parameters:
    ///   - userId: the id of the user who is deleting an conversation i.e the caller
    ///   - recieverID: the id of the person , of whom you want to delete the conversation
    ///   - convoId: the mutual conversation id of both the users i.e you and the person of whom you want to delete the conversation
    ///   - completion: completion handler , which return true on sucesss and return false on failure
    func deleteConversation(for userId: String , recieverID: String,convoId: String, completion: @escaping (Bool) -> ()){
        
        // get document with id = userId , i.e data of the user with id = userId
        DatabaseManager.db.collection("users").document(userId).getDocument(completion: { documentSnapshot, err in
            // if error occurs
            if let err = err {
                // return the error
                completion(false)
                print("Error at Line 390: DbManager: ",err.localizedDescription)
                return
            }
            // if document is empty
            guard let document = documentSnapshot else {
                // return error
                completion(false)
                print("Error at Line 397: DbManager: while deleting conversation")
                return
            }
           
            // if document contains no data
            guard var data = document.data()?["conversations"] as? [[String:Any]] else {
                // return error
                completion(false)
                print("Error at Line 405: DbManager: while deleting conversation")
                return
            }
            
            // else the document contains data
       
            var index = 0 // variable, which will contain the index of the conversation to be deleted
            // for every conversation(data) in dictionary (conversation array in firestore)
            for dictionary in data {
                // check if conversation Id is same as the convoId passed as paramter, if it is , it means that , this is the same person , with whom that caller user wants to delete his conversation
                if let conversationId = dictionary["id"] as? String  ,conversationId == convoId {
                   break
                }
                // if thats not the case , then move to next conversation in the array i.e index will be incremented
                index += 1
            }
            
            // remove the conversation from the list at the index = index
            // keep it in mind that it is not possible that index would be 0 , index would always have non zero value , because obiously the user cannot remove the conversation which doesnt exist , so it would definitely have some non zero value
            data.remove(at: index)
        
            // now assign the above upgraded data , to the conversation field in the firestore
            DatabaseManager.db.collection("users").document(userId).setData([
                "conversations": data
            ], merge: true)
            
            
            
            // checking if the reciever has still got your your conversation or not
            self.checkIfTheRecipientHasStillGotYourConversation(recieverUid: recieverID, senderUid: userId) { result in
                
                switch result {
                    
                case .failure(_):
                    // if doesn't ,then delete the whole conversation i.e messages , from the "Messages" collection to reduce space consumption
                    DatabaseManager.db.collection("Messages").document(convoId).delete { err in
                        // if err occurs while doing so
                        if let err = err {
                            // it means that we were unable to delete the messages from the firestore , but our operation to delete the conversation was successful , so no error at this place , this would result in extra memory use in firestore just, it'll not count as an error, techniqally
                            print("Error at line 446 DbManager:", err.localizedDescription)
                        }
                    }
                    break
                    
                default:
                    break
                    
                    
                }
                
            }
            // if the instruction pointer is successful in reaching this place , then it means all went well , so return true
            completion(true)
            print("Success in deleting conversation: Line 460 , DBManager File")
        })
    }
    
    
    
    /// This function checks, if the reciever has currently got access to your conversation or not i.e may be he deleted it from his side or may be not
    /// - Parameters:
    ///   - recieverUid: the user Id of the reciepient
    ///   - senderUid: the user id of the sender
    ///   - completion: completion handler , which returns the corresponding conversation Id on success and returns error on failure
    func checkIfTheRecipientHasStillGotYourConversation(recieverUid: String,senderUid: String,completion: @escaping (Result<String,Error>) -> () ) {
        
        // get document with id = recieverUid i.e the data of reciever side with this id , from users collection
        
        DatabaseManager.db.collection("users").document(recieverUid).getDocument(completion: { documentSnapshot, err in
            // if operation not sucessful
            if let err = err {
                // return error
                completion(.failure(DatabaseError.UnknowError))
                print("Error at Line 480: DbManager: ",err.localizedDescription)
                return
            }
            
            // if document contains nothing
            guard let document = documentSnapshot else {
                // return error
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
           
            // if document data is empty
            guard let data = document.data()?["conversations"] as? [[String:Any]] else {
                // return error
                completion(.failure(DatabaseError.UnknowError))
                return
            }
            
            // else we have got our data

            var conversationId:String?  // variable to store conversation id
            // for every conversation
            for dictionary in data {
                
                // if there is a convesation in which the value of "other_user_Uid"is equal to the senderUid , it means that the recipient has still got your conversation , then in this case
                if let otherUSerId = dictionary["other_user_Uid"] as? String  ,otherUSerId == senderUid {
                    // store the conversation if that conversation
                    if let c = dictionary["id"] as? String {
                        conversationId = c
                    }
                   // and break the loop
                   break
                }
            
            }
            
            
    
            // if conversationId contains nothing , the it means that recipient doesn't have your conversation record ,so
            guard let convo = conversationId else {
                // return the error ,means that the user has no record of your converstion , he deleted it
                completion(.failure(DatabaseError.UnknowError))
                return
                
            }
            // else return the converstion id , that he has got your conversation id
            completion(.success(convo))
            
        })
    }
    
    
    
}



extension DatabaseManager {
    
    
    // MARK: Operations regarding Users's Messages data
    // All messages for conversations are stored in Messages collection
    
    /// This function returns all messages for a specific conversation
    /// - Parameters:
    ///   - id: conversationId
    ///   - creation_date: creation date of the conversation , because it is possible two users create a new conversation , exchange some messages , then one user delete the conversation from his side , then recreate the conversation with the same user , this time the conversation would be created with the same id as it was previously created with , but this time we are not supposed to show the previous messages to that user , so here using creation date , we are able to do so.
    ///   - completion: completion handler , which returns the array messages on success and returns error on failure
    public func getAllMessagesForConversation(with id: String , creation_date: Date ,completion: @escaping (Result<[Message],Error>) -> () ) {
        
       
        // From the "Messages" collection, get document with id = id , i.e all messages for conversation with id = id
        // Live fetching because of the function 'addSnapshotListener'
        DatabaseManager.db.collection("Messages").document(id).addSnapshotListener ({ documentSnapshot, err in
            
            // if document value is nil
            guard let document = documentSnapshot else {
                // return the error
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
           
            // if document contains no data
            guard let data = document.data()?["messages"] as? [[String:Any]] else {
                completion(.failure(DatabaseError.NoDataToFetch))
                return
            }
            
            // else the document contains data

            // intialize an empty array of messages
            var messages:[Message] = [Message]()
           
    
            // loop for all messages residing in the data
            for dictionary in data {
              
                // for each dictionary (message) in data (list of messages) , if any of them is nil
                guard let content = dictionary["content"] as? String,
                      let name = dictionary["name"] as? String,
                      let senderUid = dictionary["senderUid"] as? String,
                      let type = dictionary["type"] as? String,
                      let messageId = dictionary["id"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFromatter.date(from: dateString)
                    
                else {
                    // return error
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                    
                }
                
                // else
                // only consider those messages in which their sent date if greater or equal to the creation date
                if date >= creation_date {
                    
                    // get the message sender
                    let sender = Sender(senderId: senderUid, displayName: name)
                
                    // dealing with message type
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
                    // if the kind is of first three types
                    if let kind = kind {
                        // then append that kind of messsage
                        messages.append( Message(sender: sender, messageId: messageId, sentDate: date, kind: kind))
                    }
                    
                }
                
                
               
            }
            // return the list of messages on success
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
    
    
    ///  This function update the latest message field  , residing in the conversation b/w two users , this function is mainly being called as you send  message to the other person in the conversation , because in this case  the latest message field has to be updated.
    /// - Parameters:
    ///   - uid: user id of the user who is sending the message
    ///   - convo_Id: conversation id of the conversation , in which the message is being sent
    ///   - message: the actual message string , which you are sending , it may be a text , or a url in case of images or video
    ///   - sentDate: sending date , at which this messge was being sent
    ///   - completion: completion handler , which return false on failure , otherwise true
    func updateLatestMsg(uid: String, convo_Id: String, message:String, sentDate: String ,completion: @escaping (Bool) -> ()) {
        
        // get document for id = uid , means the data for the user with user id = uid
        DatabaseManager.db.collection("users").document(uid).getDocument(completion: { documentSnapshot, err in
            // if error occured
            if let err = err {
                // return false
                completion(false)
                print("Error at Line 827: DbManager: ",err.localizedDescription)
                return
            }
            
            // if document contains nil
            guard let document = documentSnapshot else {
                // return false
                completion(false)
                return
            }
           
            // else if the document contains no data regrading that user's conversation
            guard var data = document.data()?["conversations"] as? [[String:Any]] else {
                // return false
                completion(false)
                return
            }
            // else we have got data
       
            // index for tracking the conversation in conversations array i.e data
            var index = 0
            // assume that we will not be able to find the conversation
            var isFound = false
            
        
            for conversation in data {
                
                // for each conversation in the data i.e conversation list, if that conversation's id = convo_Id
                if let conversationId = conversation["id"] as? String  ,conversationId == convo_Id {
                    // then we found the conversation
                    isFound = true
                   break
                }
                // else move to the next conversation
                index += 1
            }
            
            // if conversation found
            if (isFound) {
                // update latest message for that conversation
                data[index]["latest_message"] = [
                    "date": sentDate,
                    "is_read": false,
                    "message": message
                ]
            
                // update the data for conversations field in the document with id = uid
                DatabaseManager.db.collection("users").document(uid).setData([
                    "conversations": data
                ], merge: true)
                // return true on success
                completion(true)
                
            }else {
                // else return false
                completion(false)
            }
           
        })
        
    }
    
    
    
}




