
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import JGProgressHUD

class RegisterViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var firstNameField: UITextField!
    
    @IBOutlet weak var lastNameField: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var stackView: UIStackView!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var image: UIImageView!
    
    var scrollView : UIScrollView?
    
    
    
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView?.frame = view.bounds
        image.layer.cornerRadius = image.frame.width / 2.0
    

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        embedInScrollView()
        attributeImageview()
       
        
       // tap for hide keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

        view.addGestureRecognizer(tap)
        
        // tap for choosing image from the gallery
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))

        image.addGestureRecognizer(gesture)
        
        
        assignDelegatesToFields()
    
        
        
        setUpElements()
    }
    
    func embedInScrollView(){
        
        scrollView = UIScrollView()
        scrollView?.clipsToBounds = true
        view.addSubview(scrollView!)
        scrollView?.addSubview(image)
        scrollView?.addSubview(stackView)
    }
    
    func attributeImageview(){
        image.layer.masksToBounds = true
        image.layer.borderWidth = 2
        image.layer.borderColor = UIColor.lightGray.cgColor
        image.isUserInteractionEnabled = true
    }
    func assignDelegatesToFields(){
        // assigning delegate for text field
        passwordField.delegate = self
        emailField.delegate = self
        firstNameField.delegate = self
        lastNameField.delegate = self
    }

    @objc func didTapChangeProfilePic(){
        
        presentActionSheet()
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
        Utlities.styleTextField(firstNameField)
        Utlities.styleTextField(lastNameField)
        Utlities.styleButtons(registerButton)
    }
    
    @IBAction func registerClicked(_ sender: Any) {
        
        if let result = validateCredentials() {
            Utlities.displayError(result: result, view: self)
        
            
        }else {
            self.spinner.show(in: view)
            
            
            let firstname = firstNameField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let lastname = lastNameField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let email = emailField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // create the user
            
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] (result,err) in
                
                guard let strongSelf = self else { return }
                
                DispatchQueue.main.async(execute: strongSelf.spinner.dismiss)
                
                if let err = err {
                    
                    Utlities.displayError(result: err.localizedDescription, view: strongSelf)
                    
                    
                } else {
                    
                    // store in database
                    /// get image filename
                    let filename = result!.user.uid + ".png"
                    /// get current user
                    let usr:User = User.Instance(firstName: firstname, lastName: lastname, email: email,  uid: result!.user.uid)
                    
                    // storing ...(if successful)
                    if DatabaseManager.loadUserToDb(usr: usr, view: strongSelf) {
                        
                        
                        // store user profil image to storage
                        if StorageManager().uploadImage(fileName: filename, image: strongSelf.image, view: strongSelf) {
                            

                            UserDefaults.standard.set(firstname, forKey: "fName")
                            UserDefaults.standard.set(lastname, forKey: "lName")
                            // transision to the home page
                            strongSelf.transitionToHome()
                            
                        }else{
                            
                            Utlities.displayError(result: "Error saving your data!", view: strongSelf)
                        }
                        
                    }
                    
                 }
            }
            
            
        }
        
        
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
    
    func validateCredentials() -> String?{
        
        if emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            
            return "All fields are required"
        }
        
        if let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {

            if password.count < 6 {
                return "Password must be greater or equal then 6 characters"
            }


        }
        
        return nil
    }

}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func presentActionSheet(){
        
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to proceed?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {[weak self] _ in
            
            self?.presetCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { [weak self] _ in
            
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
        
    }
    
    func presetCamera() {
        
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        
        if let selectImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            self.image.image = selectImage
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true)
    }
}
