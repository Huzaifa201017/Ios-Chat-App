
import Foundation
import UIKit
import FirebaseAuth

final class Utlities {

    
    static func styleTextField(_ textField: UITextField){
        
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 12
        textField.layer.borderColor = UIColor.lightGray.cgColor
        
    
    }
    
    static func styleButtons(_ btn: UIButton){
        
        btn.layer.cornerRadius = 12
        
    }
    
    static func displayError(result:String , view:UIViewController){
        
        let alert = UIAlertController(title: "Woops!", message: result, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel,handler: nil))
        view.present(alert, animated: true)
    }
    
    public func setCurrUser(currUser: FirebaseAuth.User,  completion: @escaping (Bool) -> ()){
    
        let uid = currUser.uid
        let email = currUser.email
        let filename = uid + ".png"
        
        // get firstname and lastname from database
        DatabaseManager().getUserName(uid: uid) {  result in
            
            switch result {
                
            case .success(let data):

                guard let userData = data as? [String:Any],
                      let firstname = userData["firstname"] as? String,
                      let lastname = userData["lastname"] as? String
                        
                else {return}
        
                
                UserDefaults.standard.set(firstname, forKey: "fName")
                UserDefaults.standard.set(lastname, forKey: "lName")
  
                let usr = User.Instance(firstName:firstname ,lastName:lastname, email: email!, uid: uid)

                usr.setUrl(path:"images/\(filename)")
                
                completion(true)
             
            case .failure(let err):
                print("Utilities: func: setCurrUser: Line 55: ",err)
                completion(false)
            }
        }



//        var f = " ", l = " "
//        (f,l) = self.getName()
        
        

    }

    func getName() -> (String,String) {
        
        if let fName = UserDefaults().string(forKey: "fName") {
            if let lName = UserDefaults().string(forKey: "lName"){
                print(fName, " ", lName)
                return (fName, lName)
            }
        }

        return (" ", " ")
    }
}
