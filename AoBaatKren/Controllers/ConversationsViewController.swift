
import UIKit
import JGProgressHUD

final class ConversationsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var conversationsLabel: UILabel!
    
    var conversations: [Conversation]?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // hide them intitially
        self.tableView.isHidden = true
        conversationsLabel.isHidden = true
        
        
        tableView.dataSource = self
        tableView.delegate = self
        
        print("ConvoController: Line 30: FirstName: ",User.Instance().firstName)
        
        self.listeningToConversations()
        
        
        
    }
    
    func listeningToConversations(){
        
        DatabaseManager().getAllConversations(for: User.Instance().uid) { [weak self] result in
            switch result {
                
            case .success(let conversations):
                self?.conversations = conversations
                
                if let c = self?.conversations{
                    self?.tableView.isHidden = false
                    
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                    
                    print("Success in getting Conversation with count: (Line 53): ", c.count)
                }
                break
            case .failure(let err):
                print("Error at Line 57: ConvoController: ","\(err)")
                self?.tableView.isHidden = true
                self?.conversationsLabel.isHidden = false
                break
            }
            
        }
    }
    
    @IBAction func didTapComposeButton(_ sender: Any) {
        
        // to create instance of new controller
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "newConversations") as? NewConversationsViewController
        
        
        if let vc = vc {
            
            // get the data passed by 'NexConversationsController' and move to the conversations page of that corresponding user , just recieved!
            vc.completion = { [weak self] result in
                
                if let convo = self?.checkConvoDuplicacy(uid: result.uid){
                    
                    self?.moveToChatPageFromConversationsPage(name: convo.name, uid: convo.otherUserUid, conversation_Id: convo.id, creation_date: convo.creation_date)
                }else {
                    
                    DatabaseManager().checkIfYourChatStillExists(recieverUid: result.uid, senderUid: User.Instance().uid) { [weak self] result2 in
                        
                        switch result2 {
                            
                        case .success(let convoId):
                            self?.moveToChatPageFromConversationsPage(name:result.firstName + " " + result.lastName , uid: result.uid, conversation_Id:convoId)
                        case .failure(let err):
                            print("Error at line 90 , Convo Controller: means that user you selected is new for yoy , so you will be creating new conversation with him now:",err)
                            self?.moveToChatPageFromNewConversationsPage(user:result)
                            
                        }
                    }
                    
                }
                
                
                
                
                
            }
            
            // present the  new conversations controller
            let navigationVC = UINavigationController(rootViewController: vc)
            present(navigationVC, animated: true) // present the page as popover
            
            
        }
        
        
        
    }
    
    func checkConvoDuplicacy(uid: String) -> Conversation?{
        
        if let conversations = self.conversations {
            
            for convo in conversations{
                if uid == convo.otherUserUid {
                    
                    return convo
                }
            }
            return nil
        }
        return nil
    }
    func moveToChatPageFromNewConversationsPage(user: User ) {
        
        let vc = ChatViewController(uid:user.uid)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.title = user.firstName + " " + user.lastName
        vc.isNewConversations = true
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
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






extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ConversationTableViewCell
        
        let convo = self.conversations![indexPath.row]
        
        
        cell!.tableViewMessage.text = convo.latestMsg.text
        cell!.tableViewUserName.text = convo.name
        cell!.SetImage(uid:convo.otherUserUid)
        cell!.accessoryType = .disclosureIndicator
        return cell!
        
        
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let convo = self.conversations{
            return convo.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations![indexPath.row]
        self.moveToChatPageFromConversationsPage(name: model.name, uid: model.otherUserUid, conversation_Id: model.id, creation_date: model.creation_date)
        
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return UITableViewCell.EditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        tableView.beginUpdates()
        let convo = self.conversations![indexPath.row]
        
        // TODO: Check if there is other user accessing this conversation , if not then also delete the list of all messages from messages collection , as nobondy will be now using these messages
        // remove from database
        DatabaseManager().deleteConversation(for: User.Instance().uid, recieverID: convo.otherUserUid,convoId: convo.id) {[weak self] result in
            if result {
                self?.conversations?.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .left)
                
                if self?.conversations!.count == 0 {
                    self?.conversations = nil
                    self?.tableView.isHidden = true
                    self?.conversationsLabel.isHidden = false
                }
            }
        }
        
        
        tableView.endUpdates()
        
        
    }
    
}
