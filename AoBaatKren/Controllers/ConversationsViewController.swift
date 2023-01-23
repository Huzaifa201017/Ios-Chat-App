
import UIKit
import JGProgressHUD

final class ConversationsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var conversationsLabel: UILabel!  // label with text "No conversations"
    
    
    
    var conversations: [Conversation]? // array of conversations to be presented on this controller

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // hide them intitially
        self.tableView.isHidden = true
        conversationsLabel.isHidden = true
        
        // setting the datasource and delegate for table view
        tableView.dataSource = self
        tableView.delegate = self
        
        print("ConvoController: Line 27: FirstName: ",User.Instance().firstName)
        
        // start listening to conversations
        self.listeningToConversations()
        
        
        
    }

    
    // MARK: On pressing compose button
    // this function will be called
    @IBAction func didTapComposeButton(_ sender: Any) {
        
        // create instance of new controller
        // - get the reference of storyboard residing in your folder
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        // get the reference of view controller , designed in that storyboard , with the identifier = newConversations
        let vc = storyBoard.instantiateViewController(withIdentifier: "newConversations") as? NewConversationsViewController
        
        // if view controller's reference is not empty
        if let vc = vc {
            
            // get the data passed by 'NewConversationsController' and move to the conversations page of that corresponding user , just recieved!
            // actually what is happening there is that , we have a completion handler defined in the NewConversationsViewController , so when a user selects some person o start a new conversation with , then we need that selected data , so we have implemented the closure , so when the users selects , that closure is called there , so here also by callling that same closure we can get the data which the person has selected
            vc.completion = { [weak self] result in
                // now you have selected the user
                // check the conversation duplicacy i.e whether you have got already a conversation with that person of id = uid , on this page
                if let convo = self?.checkConvoDuplicacy(uid: result.uid){
                    // if yes
                    // then no need to start new convo , just move to chat controller and pass that conversation id
                    self?.moveToChatPageFromConversationsPage(name: convo.name, uid: convo.otherUserUid, conversation_Id: convo.id, creation_date: convo.creation_date)
                }
                // if no
                else {
                    // then it means we have to start a new conversation with the other user, but wait isnt it possible that you two people have'd a conversation in the past , but you deleted it from your side , so for other user , that conversation still exists , because if it does , we must use the same conversation id , because we want that the other user should still be able to see the previous messages , although from your side it is new , but from his side it is not new , so we are supposed to use the same conversation id , so check it
                    DatabaseManager().checkIfTheRecipientHasStillGotYourConversation(recieverUid: result.uid, senderUid: User.Instance().uid) { [weak self] result2 in
                        
                        switch result2 {
                            // if you've had a conversation in the past
                        case .success(let convoId):
                            // then no need to start new convo , just move to the chat page , and pass that conversation id
                            self?.moveToChatPageFromConversationsPage(name:result.firstName + " " + result.lastName , uid: result.uid, conversation_Id:convoId)
                            
                            break
                            // if not
                        case .failure(let err):
                            // then there is only one thing possible that you have to start a new conversation with him , so just move to chat page , with no conversation id passed (as no conversation existed before)
                            print("Error at line 75 , Convo Controller: means that user you selected is new for yoy , so you will be creating new conversation with him now:",err)
                            self?.moveToChatPageFromNewConversationsPage(user:result)
                            
                        }
                    }
                    
                }
                
                
                
                
                
            }
            
            // now only one thing left , which is shifting to the next page , so do it
            // present the  new conversations controller
            let navigationVC = UINavigationController(rootViewController: vc)
            present(navigationVC, animated: true) // present the page as popover
            
            
        }
        
        
        
    }
    
   
    
}






extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    
    // MARK: Conforming to datasource protocols
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        // tell the tableview , that which data to be displayed at cell of index = indexpath
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ConversationTableViewCell
        
        // setting the data
        let convo = self.conversations![indexPath.row]
        cell!.tableViewMessage.text = convo.latestMsg.text
        cell!.tableViewUserName.text = convo.name
        cell!.SetImage(uid:convo.otherUserUid)
        cell!.accessoryType = .disclosureIndicator
        
        
        return cell!
        
        
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        // number of sections you want to have in your table view
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let convo = self.conversations{
            return convo.count
        }
        
        return 0
    }
    
    
    // MARK: Conforming to delegate protocols
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // on selecting the row at indexpath  move to the chatviewcontroller page , with the conversation data for this index i.e model
        let model = conversations![indexPath.row]
        self.moveToChatPageFromConversationsPage(name: model.name, uid: model.otherUserUid, conversation_Id: model.id, creation_date: model.creation_date)
        
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        // here we are saying that set the editing style to delete , so the style is that the user will swipe left and there would be a button on the right of the row to delete that row
        return UITableViewCell.EditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // so when the user commit tht editing style i.e press that delete button , this function will be called
        
        tableView.beginUpdates()
        
        let convo = self.conversations![indexPath.row]
        
        // remove from database
        DatabaseManager().deleteConversation(for: User.Instance().uid, recieverID: convo.otherUserUid,convoId: convo.id) {[weak self] result in
            
            // if success
            if result {
                // remove it from the array too
                self?.conversations?.remove(at: indexPath.row)
                // apply delete row effect to the table view , so this would delete the row smoothly
                tableView.deleteRows(at: [indexPath], with: .left)
                // if after deleting that conversation , you are left with no conversation
                if self?.conversations!.count == 0 {
                    // then unhide the label
                    self?.conversations = nil
                    self?.tableView.isHidden = true
                    self?.conversationsLabel.isHidden = false
                }
                
            }
        }
        
        
        tableView.endUpdates()
        
        
    }
    
}


extension ConversationsViewController {
    
    
    // MARK: All helper functions defined here
    
    /// continuoulsy listen to the conversations (live) , means if some other person start a new conversaion with you and you are on that page , so it will automatically update your data on the table view , no need to refresh the page , this function will be called , automatically as there is some changes in the firestore for conversations
    func listeningToConversations() {
        // get all the conversation from firestore
        DatabaseManager().getAllConversations(for: User.Instance().uid) { [weak self] result in
            switch result {
                
            // if success
            case .success(let conversations):
                // store these conversations
                self?.conversations = conversations
                
                // if there are non zero conversations
                if let c = self?.conversations{
                    // then unhide the table view
                    self?.tableView.isHidden = false
                    self?.conversationsLabel.isHidden = true
                    
                    // reload the table view to refresh the changes
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                    
                    print("Success in getting Conversation with count: (Line 56): ", c.count)
                }
                break
                
                // in case of failure
            case .failure(let err):
                
                print("Error at Line 65: ConvoController: ","\(err)")
                // hide the table view and unhide the conversationsLabel
                self?.tableView.isHidden = true
                self?.conversationsLabel.isHidden = false
                break
            }
            
        }
    }
    
    
    
    /// checks whether you have already got a conversation , in the conversation list
    /// - Parameter uid: recipient id (the user with which you want to start new convo)
    /// - Returns: return conversation if it already exists with that user
    func checkConvoDuplicacy(uid: String) -> Conversation? {
        
        // if conversation list is not empty
        if let conversations = self.conversations {
            // then loop through all conversations
            for convo in conversations{
                // and check for each convo , whether he value of attribute 'otherUserUid' of that conversation equals uid or not
                if uid == convo.otherUserUid {
                    // if it is then the convo already exists , just return it
                    return convo
                }
            }
            return nil
        }
        // else return nil
        return nil
    }
    
    
    
    /// loads the ChatViewController page , considering that you have got no convoId yet , as in you are starting a purely new conversation
    /// - Parameter user: recipient user object
    func moveToChatPageFromNewConversationsPage(user: User ) {
        
        let vc = ChatViewController(uid:user.uid)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.title = user.firstName + " " + user.lastName
        vc.isNewConversations = true
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    /// loads the ChatViewController page , considering that you have got some convoId  , as in you are not starting a purely new conversation
    /// - Parameters:
    ///   - name: name of the recipient
    ///   - uid: user id of the recipient
    ///   - conversation_Id: conversation Id (as it already exists)
    ///   - creation_date: creation date of the conversation , its value would be normally the value residing in the conversation object , but if there is the case , that other user has got your conversation but you once deleted it from your side in the past , now its value would be = current date of the day
    func moveToChatPageFromConversationsPage(name: String, uid: String, conversation_Id: String, creation_date: Date = Date()) {
        
        let vc = ChatViewController(uid:uid)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.title = name
        vc.convo_creation_date = creation_date
        vc.conversation_Id = conversation_Id
        vc.isNewConversations = false
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
}
