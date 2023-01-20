

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVKit


final class ChatViewController: MessagesViewController {
    
    var recieverUid: String
    var senderUid: String
    var senderImageURL: URL?
    var recieverImageURL: URL?
    var isNewConversations:Bool
    private var messages = [Message]()
    private var selfSender: Sender?
    var conversation_Id: String?
    var convo_creation_date:Date?
    
    
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
        
        // Do any additional setup after loading the view.
        
        let u = User.Instance().firstName + User.Instance().lastName
        selfSender = Sender(senderId: self.senderUid, displayName: u)
 

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messageCellDelegate = self
        

        setInputButton()
        
        if let convo = self.conversation_Id {
            self.listenToMessages(convID: convo)
        }
        
    }
    
    func setInputButton() {
        
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: true)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    func presentActionSheet() {
        
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default , handler: { _ in
        
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default , handler: { [weak self] _ in
        
            self?.presentActionSheetForVideo()
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default , handler: { [weak self] _ in
        
            self?.presentActionSheetForPhotos()
            
        }))
   
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
        
    }
    func presentActionSheetForPhotos(){
        
        let actionSheet = UIAlertController(title: "Photos", message: "Where would you like to choose the photos from?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {[weak self] _ in
            self?.presetCamera()

        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {[weak self]  _ in
            self?.presentPhotoPicker()

        }))
        
        present(actionSheet, animated: true)
    }
    
    func presentActionSheetForVideo(){
        
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to choose the Video from?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] _ in
            self?.presetCameraForVideo()

        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[weak self]  _ in
            self?.presentVideoPicker()

        }))
        
        present(actionSheet, animated: true)
    }

    
    func listenToMessages(convID: String) {
        
        DatabaseManager().getAllMessagesForConversation(with: convID, creation_date: convo_creation_date!) { [weak self] result in
            switch result {
                
            case .success( let messages):
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadData()
                }
                

                break
            case .failure( let err):
                
                print("Error occured in fetching the messages at Line 237 ChatVC: ",err )
                break
                
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    
}








extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate, MessageCellDelegate {
    
    
    func currentSender() -> MessageKit.SenderType {
        return selfSender!
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        print(self.messages.count, "---")
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        guard let message = message as? Message else {return}
        
        switch message.kind {
            
        case .photo(let media):
            let url = media.url
            imageView.sd_setImage(with: url)
            break
        default:
            break
            
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let index = messagesCollectionView.indexPath(for: cell) else {return}
        let message = messages[index.section]
        
        switch message.kind {
            
        case .photo(let media):
            let url = media.url
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyBoard.instantiateViewController(withIdentifier: "PhotoViewer") as! PhotoViewerViewController
            viewController.url = url
           
            self.navigationController?.pushViewController(viewController, animated: true)
            break
        
        case .video(let media):
            guard let url = media.url else {return}
            
            let vc = AVPlayerViewController()
            vc.player =  AVPlayer(url: url)
            present(vc,animated: true)
            break
        default:
            break
            
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId {
            return .link
        }
        
        return .secondarySystemBackground
    }
    
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
       
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            
            if self.senderImageURL == nil {
                
                let imgPath = "images/\(self.senderUid).png"
                StorageManager().downloadURL(for: imgPath) { [weak self] result in
                     switch result {
                     case .success(let url):

                         self?.senderImageURL = url
                         DispatchQueue.main.async {
                             avatarView.sd_setImage(with: url)
                         }
                         
                     case .failure(let err):
                         print("Error fetching Image: Chat VC: 348" , err)
                     }
                 }
                
            }else{
                avatarView.sd_setImage(with: self.senderImageURL!)
            }
            
            
            
            
            
        } else {
            
            if self.recieverImageURL == nil {
                
                let imgPath = "images/\(self.recieverUid).png"
                StorageManager().downloadURL(for: imgPath) { [weak self] result in
                     switch result {
                     case .success(let url):
                         self?.recieverImageURL = url
                         DispatchQueue.main.async {
                             avatarView.sd_setImage(with: url)
                         }
                         
                     case .failure(let err):
                         print("ChatVC: Line 375: ","Error fetching Image:" , err)
                     }
                 }
                
            }else {
                
                avatarView.sd_setImage(with: self.recieverImageURL!)
                
            }
           
            
        }
    }
}

extension  ChatViewController: InputBarAccessoryViewDelegate{
    
    private func createMsgId() -> String {
        
        // date , otherUserUid , senderUid, randomInt
        let dateString = Self.dateFromatter.string(from: Date())
        let newIndeitifer = "\(self.recieverUid)_\(self.senderUid)_\(dateString)"
        return newIndeitifer
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else{
            return
            
        }
        let messageId = self.createMsgId()
        let message = Message(sender: self.selfSender!, messageId: messageId, sentDate: Date(), kind: .text(text))
        
        if isNewConversations {
        
            // create convo in database
            DatabaseManager().createNewConversation(with: self.recieverUid, msgId: messageId , firstMessage: message,otherPersonName: self.title!) { [weak self] success in
                
                if success {
                    
                    print("Messsage sent(New Convo): Line 415: Chat VC")
                    let convoId = "conversations_\(messageId)"
                    self?.conversation_Id = convoId
                    self?.isNewConversations = false
                    self?.convo_creation_date = message.sentDate
                    DispatchQueue.main.async {
                        self?.listenToMessages(convID: convoId)
                    }
                   
                    self?.messageInputBar.inputTextView.text = nil
                    
                    
                } else {
                    print("Failed to sent at line 428 ChatVC")
                }
            }
            
        } else {
            
            
            DatabaseManager().sendMessage(to: self.conversation_Id!, otherPersonName: self.title!, otherPersonUid: self.recieverUid ,message: message) { [weak self] success in
                
                if success {
                    print("Messsage sent at Line 436 ChatVC")
                    self?.messageInputBar.inputTextView.text = nil
                    
                }else{
                    print("Failed to sent at line 440 ChatVC")
                }
            }
            
        }
    }
}



extension ChatViewController: UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        
        let messageId = createMsgId()
        let fileName = "photo_message_" + messageId + ".png"
        
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
           print("Image Selected Successful at line 507 ChatVC")
       
            StorageManager().uploadMessageImage(fileName: fileName, image: selectedImage) {[weak self] result in
                
                
                guard let strongSelf = self else {return}
                
                switch result {
                    
                case .failure(let err):
                    print("ChatVC:Line 285:",err)
                    break
                case .success(let url):
                    print("Message Photo Url(ChatVC Line 520): ", url.absoluteString)
                    
                    guard let recieverName = self?.title,
                    let placeHoler = UIImage(systemName: "plus") else {return}
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeHoler, size: .zero)
                    
                    let message = Message(sender: strongSelf.selfSender!, messageId: messageId, sentDate: Date(), kind: .photo(media))
                    
                    
                    // ================================================================================
                    
                    if strongSelf.isNewConversations {
                        
                       
                        // create convo in database
                        DatabaseManager().createNewConversation(with: strongSelf.recieverUid, msgId: messageId , firstMessage: message,otherPersonName: strongSelf.title!) { [weak self] success in
                            
                            if success {
                                print("Messsage sent ChatVC Line 539")
                                let convoId = "conversations_\(messageId)"
                                self?.conversation_Id = convoId
                                self?.isNewConversations = false
                                self?.convo_creation_date = message.sentDate
                                
                                DispatchQueue.main.async {
                                    self?.listenToMessages(convID: convoId)
                                }
                    
                                
                                
                            }else {
                                print("Failed to sent at line 552 ChatVC")
                            }
                        }
                        
                    } else {
                        
                        DatabaseManager().sendMessage(to: (strongSelf.conversation_Id!), otherPersonName: recieverName, otherPersonUid: strongSelf.recieverUid, message: message) { result in
                            
                            if result {
                                print("Video Messge Sent Line 489")
                            }else{
                                print("Error in sending Video Messge , Line 491")
                            }
                        }
                        
                    }
                    
                    
                    
                    
                    // ================================================================================
                    
                    break
                }
                
                
                
            }
            
        }else if var videoUrl = info[.mediaURL] as? URL{
            
            // video choosen
            
            let fileName = "video_message_" + messageId + ".mov"
            
            // upload video
            
            if #available(iOS 13, *) {
                //If on iOS13 slice the URL to get the name of the file
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
           
            StorageManager().uploadMessageVideo(url: videoUrl,fileName: fileName) {[weak self] result in


                guard let strongSelf = self else {return}

                switch result {

                case .failure(let err):
                    print("ChatVC Error:Line 599:",err)
                    break
                case .success(let url):
                    print("Message Video Url Line 602 ChatVC: ", url.absoluteString)

                    guard let recieverName = self?.title,
                    let placeHoler = UIImage(systemName: "plus") else {return}

                    let media = Media(url: url, image: nil, placeholderImage: placeHoler, size: .zero)

                    let message = Message(sender: strongSelf.selfSender!, messageId: messageId, sentDate: Date(), kind: .video(media))


                    // ================================================================================

                    if strongSelf.isNewConversations {


                        // create convo in database
                        DatabaseManager().createNewConversation(with: strongSelf.recieverUid, msgId: messageId , firstMessage: message,otherPersonName: strongSelf.title!) { [weak self] success in

                            if success {
                                print("Messsage sent at Line 620 ChatVC")
                                let convoId = "conversations_\(messageId)"
                                self?.conversation_Id = convoId
                                self?.isNewConversations = false
                                self?.convo_creation_date = message.sentDate

                                DispatchQueue.main.async {
                                    self?.listenToMessages(convID: convoId)
                                }



                            }else {
                                print("Failed to sent at line 633 ChatVC")
                            }
                        }

                    } else {
                        DatabaseManager().sendMessage(to: (strongSelf.conversation_Id!), otherPersonName: recieverName, otherPersonUid: strongSelf.recieverUid, message: message) { result in

                            if result {
                                print("Video Messge Sent Line 489")
                            }else{
                                print("Error in sending Video Messge , Line 491")
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
        
        picker.dismiss(animated: true)
    }
}
