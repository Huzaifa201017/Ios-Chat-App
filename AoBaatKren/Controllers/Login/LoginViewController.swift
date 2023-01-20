
import UIKit

import FirebaseAuth
import JGProgressHUD

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var logInButton: UIButton!
    
    private let spinner = JGProgressHUD(style: .dark)
    

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Looks for single or multiple taps.
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

        view.addGestureRecognizer(tap)
        
        // assigning delegate for text field
        passwordField.delegate = self
        emailField.delegate = self

        // Do any additional setup after loading the view.
        setUpElements()
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField{
            
            nextField.becomeFirstResponder()
        }else{
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    

    func setUpElements(){
        Utlities.styleTextField(emailField)
        Utlities.styleTextField(passwordField)
        Utlities.styleButtons(logInButton)
    }
    
    @IBAction func loginClicked(_ sender: Any) {
        
        if let result = validateCredentials(){
            
            Utlities.displayError(result:result,view:self)
            
        }else{
            
            self.spinner.show(in: view)
            
            // login through firebase
            let email = emailField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            Auth.auth().signIn(withEmail: email, password: password) {  [weak self] result, err in
                
                guard let strongSelf = self else { return }
                
                
                
                if let err = err {
                    Utlities.displayError(result: err.localizedDescription, view: strongSelf)
                    DispatchQueue.main.async(execute: strongSelf.spinner.dismiss)
                    
                } else {
                    
                   
                    Utlities().setCurrUser(currUser: result!.user) { result in
                        if result {
                            
                            DispatchQueue.main.async {
                                strongSelf.spinner.dismiss()
                            }
                            
                            strongSelf.transitionToHome()
                        }
                    }
    
                   
                    
                   
                    
                   
                    
                }
            }
        }
    }
    
    
    func validateCredentials() -> String? {
        
        if emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            
            return "All fields are required"
        }
    
        
        return nil
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
    
    func transitionToHome(){
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let viewController
            = storyBoard.instantiateViewController(withIdentifier: "myTabViewController") as! UITabBarController
        
        let navigationController = storyBoard.instantiateViewController(withIdentifier: "myAccountsNavController") as! UINavigationController
        
        navigationController.dismiss(animated: true)
        view.window?.rootViewController = viewController
        view.window?.makeKeyAndVisible()
    }
    
}
