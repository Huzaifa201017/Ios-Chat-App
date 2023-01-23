
import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        
        
        guard let _ = (scene as? UIWindowScene) else { return } 
        

        
        // if the user is  already log in , then:
        if let usr = Auth.auth().currentUser  {

            //  Create the instance of view controller whose identifier in the storyboard is "myTabViewController".
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let viewController
                = storyBoard.instantiateViewController(withIdentifier: "myTabViewController") as! UITabBarController
            
            
            // set current logged in user's credentials (singleton design pattern followed), so that we could be able to use this data anywhere in the app where it is needed
            self.setCurrUser(currUser: usr)
            
            
            // set the root view controller of current window to the above instantiated view controller
            self.window!.rootViewController = viewController
        
        }
    }
    
    
    /// This function simply create the instance of the user class with the credentials of current user logged in , so as in user class there is a object of user class with static access , so this object will be accessible anywhere in the app , so provides a lot of ease.
    ///
    /// - Parameter currUser: Object of Firebase's own class of User , from which we'll get the current i.e logged in user email and its user Id.
    public func setCurrUser(currUser: FirebaseAuth.User){
    
        var f = " ", l = " "
        
        let uid = currUser.uid        // get current user id (firebase id)
        let email = currUser.email    // get current user email (firebase email)
        
        // get filename(i.e userId) for the user profile picture (stored on firebase storage)
        let filename = uid + ".png"
        (f,l) = Utlities().getName()        // get current user first and last name from user defaults


        let usr = User.Instance(firstName:f ,lastName:l, email: email!, uid: uid)   // get current user instance using with above attributes

        usr.setUrl(path:"images/\(filename)")    // set url for curent user profile image (stored on firebase storage)

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

