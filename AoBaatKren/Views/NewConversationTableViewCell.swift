
import UIKit
import SDWebImage

final class NewConversationTableViewCell: UITableViewCell {

    @IBOutlet weak var recieverName: UILabel!
    @IBOutlet weak var photo: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func SetImage(uid: String) {
        photo.layer.masksToBounds = true
        photo.layer.cornerRadius = photo.frame.width / 2
        
        let imgPath = "images/\(uid).png"
       StorageManager().downloadURL(for: imgPath) { [weak self] result in
            switch result {
            case .success(let url):
                self?.photo.sd_setImage(with: url)
            
            case .failure(let err):
                print("Error fetching Image: Line 38 NewConversationTableViewCell: " , err)
            }
        }
    }

}
