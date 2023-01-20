
import UIKit
import SDWebImage

final class ConversationTableViewCell: UITableViewCell {

    @IBOutlet weak var tableViewImage: UIImageView!
    
    @IBOutlet weak var tableViewUserName: UILabel!
    
    @IBOutlet weak var tableViewMessage: UILabel!
   
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
      
   
    func SetImage(uid: String) {
        tableViewImage.layer.masksToBounds = true
        tableViewImage.layer.cornerRadius = tableViewImage.frame.width / 2
        
        let imgPath = "images/\(uid).png"
       StorageManager().downloadURL(for: imgPath) { [weak self] result in
            switch result {
            case .success(let url):
                self?.tableViewImage.sd_setImage(with: url)
            
            case .failure(let err):
                print("Error fetching Image: Line 37 ConvoTableViewCell" , err)
            }
        }
    }

    
}
