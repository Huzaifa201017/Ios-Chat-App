

import UIKit
import JGProgressHUD


final class NewConversationsViewController: UIViewController {

    
    var completion: ((User) -> ())?
    var usersCollection:[User] = [User]()
    var isFetched:Bool = false
    var results:[User] = [User]()
    let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet var searchBar: UISearchBar!

    @IBOutlet weak var noConversations: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        noConversations.isHidden = true
        self.navigationItem.titleView = searchBar
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        
        
        
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.becomeFirstResponder()
        
       
    }
    

    @objc private func dismissSelf () {
        
        self.dismiss(animated: true)
    }



}

extension NewConversationsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if let text = searchBar.text{
            searchBar.resignFirstResponder()
            spinner.show(in: view, animated: true)
            results.removeAll()
            self.searchUsers(query: text )
        }
        
        
    }
    
    func searchUsers(query: String){
        // if data  has not been fetched already: fetch it
        if !isFetched {
            DatabaseManager().getAllUsers(docId: User.Instance().uid) { [weak self] result in
                switch result {
                case .success(let users):
                    self?.usersCollection = users
                    self?.isFetched = true
                    self?.filterResults(with: query)
                   
                    
                case .failure(let err):
                    print("Failed to fetch users: Error at line 77 NewConversationController\(err)")
                }
            }
           
        }
        // filter it
        self.filterResults(with: query)
    
    }
    
    
    func updateView(){
        
        if self.results.isEmpty {
            self.noConversations.isHidden = false
            self.tableView.isHidden = true
        }else{
            self.noConversations.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
    
    func filterResults(with term:String){
        
        if !isFetched {
            return
        }
        
        spinner.dismiss(animated: true)
        
        let results: [User] = self.usersCollection.filter({
            
            let name = ($0.firstName + " " + $0.lastName).lowercased()
            return name.hasPrefix(term.lowercased())
        })
        
        self.results = results
        
        // update UI
        updateView()

    }
}



extension NewConversationsViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:NewConversationTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NewConversationTableViewCell
        
        let convo = self.results[indexPath.row]
        
        
        cell.recieverName.text = convo.firstName + " " + convo.lastName
        cell.SetImage(uid:convo.uid)
        return cell
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let result = self.results[indexPath.row]
        // dismiss that page
        self.dismiss(animated: true) {[weak self] in
            self?.completion?(result)
        }
        
    }
}


