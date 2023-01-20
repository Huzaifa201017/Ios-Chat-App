
import UIKit

final class PhotoViewerViewController: UIViewController {

   
    @IBOutlet weak var photo: UIImageView!
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.backgroundColor = .systemBackground

        navigationItem.largeTitleDisplayMode = .never

        photo.sd_setImage(with: url)
    }
    

    

}
