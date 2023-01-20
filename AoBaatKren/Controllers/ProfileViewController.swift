

import UIKit
import FirebaseAuth

final class ProfileViewController: UIViewController {

    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myView: UIView!
    
    
    var data = [ProfileViewModel]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpImage()
        setUpData()
        tableView.dataSource = self
        tableView.delegate =  self
    
        let usr = User.Instance()

        
        
        if let url = usr.url {
            
            print("URL For profile pic : (Line 38 in ProfileVC): ",url.absoluteString)
            StorageManager().downloadFile(url: url, view: self, imageView: self.headerImage)
            
        } else {
            
            let path = "images/\(usr.uid).png"
            StorageManager().downloadURL(for: path) {[weak self] result in
                
                guard let strongSelf = self else {return}
                switch result {
                    
                    case .success (let url):
                    usr.setURL(url: url)
                    StorageManager().downloadFile(url: url, view: strongSelf, imageView: strongSelf.headerImage)
                      
                    case .failure (let error):
                      print("Failed to get download url: Line 47 : ProfileVC: \(error)")
                     
                }
            }
            
            
        }

    }
    
 
    
    func setUpImage() {

        headerImage.frame = CGRect(x: Int((myView.frame.width)/2 - 90), y: 75, width: 150, height: 150)
        
        headerImage.layer.masksToBounds = true
        headerImage.layer.borderWidth = 3
        headerImage.layer.borderColor = UIColor.white.cgColor
        headerImage.layer.cornerRadius = 150 / 2
        
    }
    
    func setUpData(){
        let user = User.Instance()
        self.data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(user.firstName + " " + user.lastName)", handler: nil))
        self.data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(user.email)", handler: nil))
        self.data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out",handler: { [weak self] in
            
            guard let strongSelf = self else {return}
            
            strongSelf.presentActionSheet()
        }))
    }
    
    func presentActionSheet(){
        
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive , handler: { [weak self] _ in
            
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let viewController
                = storyBoard.instantiateViewController(withIdentifier: "myAccountsNavController") as! UINavigationController
            
            do{
                try Auth.auth().signOut()

            }catch let signOutError as NSError{
                print("Error signing out: at line 83 in profile view controller: %@", signOutError)
            }
            
            User.Instance().destroy()
            UserDefaults.standard.removeObject(forKey: "fName")
            UserDefaults.standard.removeObject(forKey: "lName")
            
            self?.tabBarController?.dismiss(animated: true)
            self?.view.window!.rootViewController = viewController
            
        }))
   
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
        
    }


}



extension ProfileViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:ProfileTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ProfileTableViewCell
        
        cell.setUp(with: data[indexPath.row])
        return cell
       

    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        data[indexPath.row].handler?()
    }
}


class ProfileTableViewCell: UITableViewCell {
    
    public func setUp(with viewModel: ProfileViewModel) {
        switch viewModel.viewModelType{
        case .info:
            if #available(iOS 14.0, *) {
                var content = self.defaultContentConfiguration()
                content.text = viewModel.title
                self.contentConfiguration = content
                
            } else {
                self.textLabel?.text = viewModel.title
            }
            break
        case .logout:
            
            if #available(iOS 14.0, *) {
                var content = self.defaultContentConfiguration()
                content.text = viewModel.title
                content.textProperties.color = .red
                content.textProperties.alignment = .center
                self.contentConfiguration = content
                
            } else {
                self.textLabel?.textColor = .red
                self.textLabel?.textAlignment = .center
                self.textLabel?.text = viewModel.title
                
            }
           break
        }
    }

}
