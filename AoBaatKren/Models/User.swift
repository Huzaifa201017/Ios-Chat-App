


import Foundation

final class User {
    
    static private var usr: User? = nil
    
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
    
    static func Instance(firstName: String, lastName: String, email: String, uid:String) -> User{
        
        if let usr = User.usr {
           
            return usr
            
        }else{
            
            User.usr = User(firstName: firstName, lastName: lastName, email: email, uid: uid)
            return User.usr!
        }
    }
    
    static func Instance() -> User {
        
        if let usr = User.usr {
           return usr
            
        }else{
            return User()
        }
        
    }
    
    public func setUrl(path: String){
        
        if User.usr != nil && self.url == nil{
           
            StorageManager().downloadURL(for: path) {[weak self] result in
                switch result {
                    
                    case .success (let url):
                     self?.setURL(url: url)
                      
                    case .failure (let error):
                      print("Failed to get download url: Line 75 : User.swift\(error)")
                     
                }
            }
        }
    }
    
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
