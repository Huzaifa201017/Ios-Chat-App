
import Foundation
import UIKit
import FirebaseAuth

final class Utlities {
    
    /// Styles the text field passed in as a parameter
    /// - Parameter textField: object of UIKIT class 'UITextField'
    static func styleTextField(_ textField: UITextField){
        
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 12
        textField.layer.borderColor = UIColor.lightGray.cgColor
        
    
    }
    
    /// Styles the button passed in as a parameter
    /// - Parameter btn: object of UIKIT class 'UIButton'
    static func styleButtons(_ btn: UIButton) {
        btn.layer.cornerRadius = 12
        
    }
    
    
    
    
    
    
    /// Displays the error popup
    /// - Parameters:
    ///   - result: error message to be displayed
    ///   - view: the view in which it is to be displayed
    static func displayError(result:String , view:UIViewController){
        
        // 'UIAlertController' ,responsible for showing such alert pop ups
        let alert = UIAlertController(title: "Woops!", message: result, preferredStyle: .alert)
        
        // add one action to this alert box
        // - action means option to be selected on the pop up , we can add as  many options as we want
        // - so here we are adding only one option.
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel,handler: nil))
        
        // present this alert box (pop up).
        view.present(alert, animated: true)
    }
    
    
    
    
    
    
    
    
    /// This function simply create the instance of the user class with the credentials of current user logged in . As in user class, there is an object of same class with static access , so this object will be accessible anywhere in the app , so provides a lot of ease.
    ///
    /// - Parameter currUser: Object of Firebase's own class of User , from which we'll get the current i.e logged in user email and its user Id.
    /// - Parameter completion: completion handler to check whether we have successfuly got our user object or not.
    public func setCurrUser(currUser: FirebaseAuth.User,  completion: @escaping (Bool) -> ()){
    
        let uid = currUser.uid        // get current user id (firebase id)
        let email = currUser.email    // get current user email (firebase email)
        
        // get filename(i.e userId) for the user profile picture (stored on firebase storage)
        let filename = uid + ".png"
        
        // get firstname and lastname from database
        DatabaseManager().getUserDocumentData(uid: uid) {  result in
            
            switch result {
                // if operation successful,
            case .success(let data):

                // and all the values are non nil:
                guard let userData = data as? [String:Any],
                      let firstname = userData["firstname"] as? String,
                      let lastname = userData["lastname"] as? String
                        
                else {return}
        
                // then store the first and lastname in the user defaults for future use e.g when the user turn off the app without logging out and turn the app on again (the user is still logged in this time , so we will get these names from user defaults , as done in the file 'sceneDelegate'
                UserDefaults.standard.set(firstname, forKey: "fName")
                UserDefaults.standard.set(lastname, forKey: "lName")
  
                
                // create the instance of current logged in user with the above fetched credentials.
                let usr = User.Instance(firstName:firstname ,lastName:lastname, email: email!, uid: uid)

                // set url for the profile picture of the logged in user
                usr.setUrl(path:"images/\(filename)")
                
                // tell the closure that operation was successful
                completion(true)
             
                
            // if operation not successful
            case .failure(let err):
                // tell the closure that operation was not successful
                print("Utilities: func: setCurrUser: Line 92: ",err)
                completion(false)
            }
        }

        
        

    }

    /// Simply returns the first and last name of the user stored in User Defaults
    /// - Returns: tuple , containing first and lastname of user
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
