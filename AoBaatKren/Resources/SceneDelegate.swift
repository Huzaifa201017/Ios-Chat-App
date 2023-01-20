
import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        
        
        guard let _ = (scene as? UIWindowScene) else { return } 
        

        if let usr = Auth.auth().currentUser  {

            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let viewController
                = storyBoard.instantiateViewController(withIdentifier: "myTabViewController") as! UITabBarController
            
            self.setCurrUser(currUser: usr)
            
            self.window!.rootViewController = viewController
        
        }
    }
    
    public func setCurrUser(currUser: FirebaseAuth.User){
    
        let uid = currUser.uid
        
        let email = currUser.email
        let filename = uid + ".png"
        
        var f = " ", l = " "
        (f,l) = self.getName()


        let usr = User.Instance(firstName:f ,lastName:l, email: email!, uid: uid)

        usr.setUrl(path:"images/\(filename)")

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
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

