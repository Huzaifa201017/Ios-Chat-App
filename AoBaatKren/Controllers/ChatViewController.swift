

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVKit


/// This controller controls the view for chat (where all the chats between two specific users are shown)
final class ChatViewController: MessagesViewController {
    
    var recieverUid: String      // recipient user Id (firebase user id)
    var senderUid: String        // sender i.e yours Id (firebase Id)
    var senderImageURL: URL?     // sender profile Image (firebase) URL
    var recieverImageURL: URL?   // recipient profile Image (firebase) URL
    var isNewConversations:Bool  // is the conversation new or not
    private var messages = [Message]()   // list of all the messages sent and recieved in this conversation
    private var selfSender: Sender?      // Sender object of Sender type(from message kit), representing the sender
    var conversation_Id: String?         // the id of conversation between these two users i.e sender and reciever
    var convo_creation_date:Date?        // when this conversation was created
    
    
    /// formats the data , according to the set dateformat and locale
    public static let dateFromatter: DateFormatter = {
        let formatter = DateFormatter()
           formatter.locale = Locale(identifier: "en_US_POSIX")
           formatter.dateFormat = "dd-MMM-yyyy 'at' h:mm:ss a Z"
           return formatter
    }()
    
    
    
    
    
    init(uid: String) {
        self.recieverUid = uid
        self.isNewConversations = true
        self.senderUid = User.Instance().uid
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        

        // get name of the sender (hint: singleton class , so accessible anywhere)
        let u = User.Instance().firstName + User.Instance().lastName
        // get sender of type Sender , representing the actual sender i. you
        selfSender = Sender(senderId: self.senderUid, displayName: u)
 
        // setting the datasource and delegate for the view
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messageCellDelegate = self
        
        // set the button
        setInputButton()
        
        // MARK: Live listening to messages here:
        // if the conversation is not new , so you would have conversation id , so
        if let convo = self.conversation_Id {
            // listen to the all the messages , which have been exchanged uptill now
            self.listenToMessages(convID: convo)
        }
        
    }

    // after the view has been displayed
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // show the keyboard from the bottom of the screen
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    
}







// MARK: All Chat related stuff here e.g loading messages , touch on messages etc
extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate, MessageCellDelegate {
    
    // Method related to MessagesDataSource protocol , which tells the data source who is the sender , so to distinguish the sender and reciever messsages
    func currentSender() -> MessageKit.SenderType {
        return selfSender!
    }
    
    // like table view , tell the datadource , which message to be displayed at specific indexpath
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    // this function is also related to MessagesDataSource protocol , which tells the datasource , how many messages are there to be displayed
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        print("Messages Count: Line 110,ChatVC: ",self.messages.count)
        return messages.count
    }
    
    // function related to MessagesDisplayDelegate protocol , which handles the photo messages i.e in displaying them
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        guard let message = message as? Message else {return}   // get the message
        // check the message kinf
        switch message.kind {
            // if it is photo message
        case .photo(let media):
            // get its url
            let url = media.url
            // set it
            imageView.sd_setImage(with: url)
            break
        default:
            break
            
        }
    }
    
    // function related to MessageCell delegate protocol , which tell the view controller what to do , when user press the photo or video message
    func didTapImage(in cell: MessageCollectionViewCell) {
        // get message
        guard let index = messagesCollectionView.indexPath(for: cell) else {return}
        let message = messages[index.section]
        // check msg kind
        switch message.kind {
            // if photo
        case .photo(let media):
            // get the url
            let url = media.url
            // move to the PhotoViewerViewController view controller
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyBoard.instantiateViewController(withIdentifier: "PhotoViewer") as! PhotoViewerViewController
            // and pass that url to this view controller
            viewController.url = url
            // finally move
            self.navigationController?.pushViewController(viewController, animated: true)
            break
        // if video
        case .video(let media):
            // get the video url
            guard let url = media.url else {return}
            // create AVPlayerViewController to play the video
            let vc = AVPlayerViewController()
            // set the player i.e which video be played
            vc.player =  AVPlayer(url: url)
            // finally present that view cotroller
            present(vc,animated: true)
            break
        default:
            break
            
        }
    }
    
    // This is a function related to MessageDisplayDelegate protocol , which tells the view controller  what shoule be the background color of the messages
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        // get the sender
        let sender = message.sender
        // if its sender message
        if sender.senderId == selfSender?.senderId {
            // then show this color
            return .link
        }
        // otherwise it is recipient message , show the secondary color , on the basis of dark or ligh mode
        return .secondarySystemBackground
    }
    
    
    // This function is related to MessageDisplayDelegate , which tells the view controller , what should be the avatar image for a message i.e for sender or reciever messages
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
       
        let sender = message.sender  // get the sender
        // if its your message
        if sender.senderId == selfSender?.senderId {
            // and sender image url is nil
            if self.senderImageURL == nil {
                // then get the image url
                let imgPath = "images/\(self.senderUid).png" // image path
                // get the url , for that path , from firebase
                StorageManager().downloadURL(for: imgPath) { [weak self] result in
                     switch result {
                         // if  success
                     case .success(let url):
                        // store that url
                         self?.senderImageURL = url
                         // set that image
                         DispatchQueue.main.async {
                             avatarView.sd_setImage(with: url)
                         }
                         // in case of failure , just print that error
                     case .failure(let err):
                         print("Error fetching Image: Chat VC: 206" , err)
                     }
                 }
                
            }
            // if image url is not nil
            else{
                // simply set the image using this url
                avatarView.sd_setImage(with: self.senderImageURL!)
            }
            
            
            
            
            
        }
        // if its not your message
        else {
            // and if the reciever image url is nil
            if self.recieverImageURL == nil {
                // same as above ...
                let imgPath = "images/\(self.recieverUid).png"
                StorageManager().downloadURL(for: imgPath) { [weak self] result in
                     switch result {
                     case .success(let url):
                         self?.recieverImageURL = url
                         
                         DispatchQueue.main.async {
                             avatarView.sd_setImage(with: url)
                         }
                         
                     case .failure(let err):
                         print("ChatVC: Line 238: ","Error fetching Image:" , err)
                     }
                 }
                
            }else {
                
                avatarView.sd_setImage(with: self.recieverImageURL!)
                
            }
           
            
        }
    }
    
    
}


//MARK: Sending messages stuff
extension  ChatViewController: InputBarAccessoryViewDelegate{
    
    /// create message id
    /// - Returns: return it
    private func createMsgId() -> String {
        
        // message Id = date + otherUserUid + senderUid (so it would be unique always)
        let dateString = Self.dateFromatter.string(from: Date())
        let newIndeitifer = "\(self.recieverUid)_\(self.senderUid)_\(dateString)"
        return newIndeitifer
    }
    
    // Function related to InputBarAccessoryViewDelegate protocol , triggered when send button is pressed
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        // if text is not empty , then proceed forwards
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else{
            return
            
        }
        // get the msg Id
        let messageId = self.createMsgId()
        // create message of Message type , that you wanna send
        let message = Message(sender: self.selfSender!, messageId: messageId, sentDate: Date(), kind: .text(text))
        // if its new conversation
        if isNewConversations {
        
            // then create that convo in database
            DatabaseManager().createNewConversation(with: self.recieverUid, msgId: messageId , firstMessage: message,otherPersonName: self.title!) { [weak self] success in
                // if success in creating
                if success {
                    
                    print("Messsage sent(New Convo): Line 289: Chat VC")
                    let convoId = "conversations_\(messageId)"
                    self?.conversation_Id = convoId
                    self?.isNewConversations = false
                    self?.convo_creation_date = message.sentDate
                    
                    // FIXME: Now here is some problem , which function gets called first and the messages in the firestore gets stored later , so because of this , nothing gets diapayed on the chat , yes but when we move back to conversation page , and then come back to this chat , then this message gets diaplayed successfully
                    
                    DispatchQueue.main.async {
                        // listen to the messsages
                        self?.listenToMessages(convID: convoId)
                    }
                    // clear the search bar
                    self?.messageInputBar.inputTextView.text = nil
                    
                    
                } else {
                    print("Failed to sent at line 306 ChatVC")
                }
            }
            
        }
        // else the conversation was not new
        else {
            
            // so just send the message
            DatabaseManager().sendMessage(to: self.conversation_Id!, otherPersonName: self.title!, otherPersonUid: self.recieverUid ,message: message) { [weak self] success in
                
                if success {
                    print("Messsage sent at Line 318 ChatVC")
                    self?.messageInputBar.inputTextView.text = nil
                    
                }else{
                    print("Failed to sent at line 322 ChatVC")
                }
            }
            
        }
    }
}


//MARK: Photo and video Messages are handled here
extension ChatViewController: UIImagePickerControllerDelegate , UINavigationControllerDelegate{

    // function related to UIImagePickerControllerDelegate , which will be triggered when you have selected the media
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // after selecting dismiss the camera or photo library , depending upon your option choosen
        picker.dismiss(animated: true)
        
        // create new messsage id
        let messageId = createMsgId()
        
        // if you selected the image
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
           print("Image Selected Successful at line 345 ChatVC")
       
            // then set the filename for your photo message to store it on firebase storage
            let fileName = "photo_message_" + messageId + ".png"
            
            // upload it to the firebase storage and get the resultant firebase url
            StorageManager().uploadMessageImage(fileName: fileName, image: selectedImage) {[weak self] result in
                
                
                guard let strongSelf = self else {return}
                
                switch result {
                    // in case of error
                case .failure(let err):
                    print("ChatVC:Line 359:",err)
                    break
                // in case of succes
                case .success(let url):
                    
                    print("Message Photo Url(ChatVC Line 364): ", url.absoluteString)
                    
                    // get these values
                    guard let recieverName = self?.title,
                          let placeHoler = UIImage(systemName: "plus")
                    else {return}
                    
                    // if successfully got , create the media object corresponding to the image selected and its url
                    let media = Media(url: url, image: nil, placeholderImage: placeHoler, size: .zero)
                    // now create the message to store it on the firestore , here the message text would be image url
                    let message = Message(sender: strongSelf.selfSender!, messageId: messageId, sentDate: Date(), kind: .photo(media))
                    
                    
                    // ================================================================================
                    // if its new conversation
                    if strongSelf.isNewConversations {
                        
                         
                        // then create this convo in database
                        DatabaseManager().createNewConversation(with: strongSelf.recieverUid, msgId: messageId , firstMessage: message,otherPersonName: strongSelf.title!) { [weak self] success in
                            // in case of success
                            if success {
                                
                                print("Messsage sent ChatVC Line 387")
                                let convoId = "conversations_\(messageId)"
                                self?.conversation_Id = convoId
                                self?.isNewConversations = false
                                self?.convo_creation_date = message.sentDate
                                
                                
                                DispatchQueue.main.async {
                                    self?.listenToMessages(convID: convoId)
                                }
                    
                                
                                
                            }else {
                                print("Failed to sent at line 400 ChatVC")
                            }
                        }
                        
                    }
                    // else the conversation is not new
                    else {
                        // just send the message
                        DatabaseManager().sendMessage(to: (strongSelf.conversation_Id!), otherPersonName: recieverName, otherPersonUid: strongSelf.recieverUid, message: message) { result in
                            
                            if result {
                                print("Photo Messge Sent Line 411")
                            }else{
                                print("Error in sending Video Messge , Line 413")
                            }
                        }
                        
                    }
                    
                    
                    
                    
                    // ================================================================================
                    
                    break
                }
                
                
                
            }
            
        }
        // else it was video message  , so get the video url
        else if var videoUrl = info[.mediaURL] as? URL{
            
            // filename with which this video would be stored on firebase storage
            
            let fileName = "video_message_" + messageId + ".mov"
            
            // upload video
            // (in ios 13 and above there is some issue that when we select video from photo library , the local url of the video contains three strings separated with . , but when we upload the video using this url , we get the error , but for ios versions below 13 , the url contains two strings separated with . , and this url works successfully , so for ios 13 we have to convert the string containting three dots , in the string containting 2 dots (.) )
            if #available(iOS 13, *) {
                // If on iOS13 slice the URL to get the name of the file
                let urlString = videoUrl.relativeString
                let urlSlices = urlString.split(separator: ".")
                if urlSlices.count == 3 {
                    //Create a temp directory using the file name
                    let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let targetURL = tempDirectoryURL.appendingPathComponent(String(urlSlices[1])).appendingPathExtension(String(urlSlices[2]))

                    //Copy the video over
                    do{
                        try FileManager.default.copyItem(at: videoUrl, to: targetURL)
                    }catch let err as NSError {
                        print(err)
                    }
                    
                    
                    videoUrl = targetURL
                }

            }
           
            
            print("Video URL: ", videoUrl)
           // upload the video with the above videurl
            StorageManager().uploadMessageVideo(url: videoUrl,fileName: fileName) {[weak self] result in


                guard let strongSelf = self else {return}

                switch result {
       
                case .failure(let err):
                    print("ChatVC Error:Line 474:",err)
                    break
                // on success
                case .success(let url):
                    print("Message Video Url Line 478 ChatVC: ", url.absoluteString)

                    // get these values
                    guard let recieverName = self?.title,
                    let placeHoler = UIImage(systemName: "plus") else {return}
                    
                    // if successfully got , create the media object corresponding to the video selected and its url
                    let media = Media(url: url, image: nil, placeholderImage: placeHoler, size: .zero)
                    // now create the message to store it on the firestore , here the message text would be video url
                    let message = Message(sender: strongSelf.selfSender!, messageId: messageId, sentDate: Date(), kind: .video(media))


                    // ================================================================================
                    
                    // if its new conversation
                    if strongSelf.isNewConversations {


                        // then create this convo in database
                        DatabaseManager().createNewConversation(with: strongSelf.recieverUid, msgId: messageId , firstMessage: message,otherPersonName: strongSelf.title!) { [weak self] success in

                            if success {
                                print("Messsage sent at Line 500 ChatVC")
                                let convoId = "conversations_\(messageId)"
                                self?.conversation_Id = convoId
                                self?.isNewConversations = false
                                self?.convo_creation_date = message.sentDate

                                DispatchQueue.main.async {
                                    self?.listenToMessages(convID: convoId)
                                }



                            }else {
                                print("Failed to sent at line 513 ChatVC")
                            }
                        }

                    } else {
                        // else the conversation is not new
                        // just send the message
                        DatabaseManager().sendMessage(to: (strongSelf.conversation_Id!), otherPersonName: recieverName, otherPersonUid: strongSelf.recieverUid, message: message) { result in

                            if result {
                                print("Video Messge Sent Line 523")
                            }else{
                                print("Error in sending Video Messge , Line 525")
                            }
                        }

                    }



                    // ================================================================================


                    break
                }



            }
            
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // when cancel button pressed on action sheet , then just dismiss that action sheet
        picker.dismiss(animated: true)
    }
    
    
}



extension ChatViewController {
    
    //MARK: All helper functions:
    
    /// This function set button , i.e the button which is on the left of search bar in the shape of paperclip , used for additional functionalities like send photo video etc
    func setInputButton() {
        
        let button = InputBarButtonItem()  // get the button
        button.setSize(CGSize(width: 35, height: 35), animated: true)  // set its size
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)  // set its image
        // on press
        button.onTouchUpInside { [weak self] _ in
            // show the action sheet
            self?.presentActionSheet()
        }
        // set its position
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    /// this function present action sheet , when he presses the paper clip button
    func presentActionSheet() {
        
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        // audio option added
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default , handler: { _ in
        
            
        }))
        // video option added
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default , handler: { [weak self] _ in
        
            self?.presentActionSheetForVideo()
            
        }))
        // Photo option added
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default , handler: { [weak self] _ in
        
            self?.presentActionSheetForPhotos()
            
        }))
        
        // cancel option added
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // present all these options
        present(actionSheet, animated: true)
        
    }
    
    /// this function presents action sheet , when user selects Photos option from the action sheet which is displayed when user press paper clip button
    func presentActionSheetForPhotos(){
        
        let actionSheet = UIAlertController(title: "Photos", message: "Where would you like to choose the photos from?", preferredStyle: .actionSheet)
        // add cancel option
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // add Take Photo option
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {[weak self] _ in
            self?.presetCamera()

        }))
        // add Choose Photo option
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {[weak self]  _ in
            self?.presentPhotoPicker()

        }))
        // present these options
        present(actionSheet, animated: true)
    }
    
    /// this function presents action sheet , when user selects Video option from the action sheet which is displayed when user press paper clip button
    func presentActionSheetForVideo(){
        
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to choose the Video from?", preferredStyle: .actionSheet)
        
        // add cancel option
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // add camera option
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] _ in
            self?.presetCameraForVideo()

        }))
        // add Photo Library option
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[weak self]  _ in
            self?.presentVideoPicker()

        }))
        // present these options
        present(actionSheet, animated: true)
    }
    
    
    /// This function listen to the messages for a specific conversation
    /// - Parameter convID: conversation Id for which u want to listen to the messages
    func listenToMessages(convID: String) {
        // get messages from the database
        DatabaseManager().getAllMessagesForConversation(with: convID, creation_date: convo_creation_date!) { [weak self] result in
            switch result {
                // on success
            case .success( let messages):
                // store the messages in the mesages variable of this class
                self?.messages = messages
                // reload collection view , as we have got new data now
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadData()
                }
                

                break
            case .failure( let err):
                
                print("Error occured in fetching the messages at Line 667 ChatVC: ",err )
                break
                
            }
        }
    }
    
    func presetCamera() {
        
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presetCameraForVideo() {
        
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.mediaTypes = ["public.movie"]
        vc.videoQuality = .typeMedium
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker(){
        
        let vc = UIImagePickerController()
        if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)){
            
            vc.sourceType = .photoLibrary
            vc.delegate = self
            vc.allowsEditing = true
            present(vc, animated: true)
        }
       
    }
    
    func presentVideoPicker(){
        
        let vc = UIImagePickerController()
        if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)){
            
            vc.sourceType = .photoLibrary
            vc.delegate = self
            vc.mediaTypes = ["public.movie"]
            vc.videoQuality = .typeMedium
            vc.allowsEditing = true
            present(vc, animated: true)
        }
       
    }
    
}
