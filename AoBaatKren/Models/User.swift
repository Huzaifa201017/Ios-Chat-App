


import Foundation


/// Class representing the user i.e the users using this app
/// We will be using singleton design pattern in this class
final class User {
    
    // static user object , requirement of singleton design pattern
    static private var usr: User? = nil
    
    // attributes
    var firstName: String
    var lastName : String
    var email: String
    var uid: String
    var url: URL? = nil
    
    
    
    private init(firstName: String, lastName: String, email: String, uid:String) {
        
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.uid = uid
        url = nil
        
    }
    private init(){
        self.firstName = ""
        self.lastName = ""
        self.email = ""
        self.uid = ""
        url = nil
    }
    init(firstName: String, lastName: String, uid:String){
        self.firstName = firstName
        self.lastName = lastName
        self.uid = uid
        self.email = ""
        url = nil
    }
    
    /// This function will actually return the instance of this class following the rules  of singleton design pattern rules . As our constructors are private , so we can't instantiate this class , using its constructor
    /// - Parameters:
    ///   - firstName: firstname of the user
    ///   - lastName: lastname of the user
    ///   - email: email of the user
    ///   - uid: user id (firebase one) of the user
    /// - Returns: return the instance of the user , with above given attributes , following the rules of Singleton design pattern
    static func Instance(firstName: String, lastName: String, email: String, uid:String) -> User{
        
        // if usr is not nil , means you have aleady created the object of this class once
        if let usr = User.usr {
            // then simply return that instance
            return usr
            
        }
        // else
        else{
            // create the instance and return it
            User.usr = User(firstName: firstName, lastName: lastName, email: email, uid: uid)
            return User.usr!
        }
    }
    

    /// This function will actually return the instance of this class following the rules  of singleton design pattern rules . As our constructors are private , so we can't instantiate this class , using its constructor
    /// - Returns: return the instance of the user following the rules of Singleton design pattern
    static func Instance() -> User {
        // if usr is not nil , means you have aleady created the object of this class once
        if let usr = User.usr {
            // return it
           return usr
            
        }
        // else
        else{
            // create the instance and return it
            return User()
        }
        
    }
    
    
    /// This function act as setter for url of the user class , but the difference between most of the setters and this setter is that , it would first fetch the url based on the parameter , then set it , other setter just take the value to be set and simply set it in one line
    /// - Parameter path: path of the image/video for which you want to set the url , this path will be the path wrt firebase e.g images/abc.png etc
    public func setUrl(path: String) {
        // if the user is not nil , and url corresponding to that user is still nil
        if User.usr != nil && self.url == nil{
           
            // then get the url , using its path
            StorageManager().downloadURL(for: path) {[weak self] result in
                switch result {
                    // in case of success
                    case .success (let url):
                    // set this url value as the value for url attribute of that user
                     self?.setURL(url: url)
                      break
                    // in case of failure
                    case .failure (let error):
                    // print the error
                      print("Failed to get download url: Line 103 : User.swift\(error)")
                     
                }
            }
        }
    }
    
    // setter for url
    public func setURL(url:URL){
        if let usr = User.usr{
            usr.url = url
        }
       
    }
    
    public func setfName(name: String){
        self.firstName = name
    }
    
    public func setlName(name: String){
        self.lastName = name
    }
    
    func destroy(){
        Self.usr = nil
    }
    
}
