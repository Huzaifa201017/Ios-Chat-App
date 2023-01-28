

import Foundation
import FirebaseStorage
import UIKit

// enum for errors, regarding fetching data from firebase storage
public enum StorageErrors: Error {
    case failedToUpload
    case failedToGetDownloadUrl
}



// class for managing upload and fetch operations, from firebase storage
final class StorageManager {
    
    // storage instance used for accesing firebase storage,
    // -- kept static so we dont have to make a new instance of storage every time
    private static let storage = Storage.storage()
    
    
    // MARK: Upload Operations
    
    /// upload image to the firebase storage.
    /// - Parameters:
    ///   - fileName: the name of image file, with which you want to store it on firebase storage. The filename can be of your own choice.
    ///   The filename should be in the format of (name.extension) e.g abc.png , user.jpeg etc .
    ///   - image: the UIImageView where the image to be uploaded is displayed.
    ///   - view: your current view controller in which you are calling this function(it is just here to diaplay error in case of operation failure , no other special purpose)
    /// - Returns: returns true in caase of succesful operation , otherwise false
    public func uploadImage(fileName:String , image:UIImageView, view:UIViewController) ->  Bool{
        
        // assume the operation would be successful
        var success = true
        // get reference to storage
        let storageRef = Self.storage.reference()
        // get the reference of the path , where you want to store the image at firebase storage
        let imagePath = storageRef.child("images/\(fileName)")
        
        // get data in bytes
        let data = image.image!.pngData()
        
        
        // store it
        imagePath.putData(data!, metadata: nil) { (metadata, error) in
            
            // if operation unsuccessful
            if let err = error {
                
                // display error to the view 'view' , passed in the paramter
                Utlities.displayError(result: err.localizedDescription, view: view)
                success = false // denoting the operation was unsuccessful
                print("Error in Uploading File: func 'uploadImage' Line 52 ", err.localizedDescription)
            }
            
            
        }
        
        // return operation status
        return success
    }
    
    
    
    
    /// upload message image to the firebase storage and returns the firebase URL of the image
    /// - Parameters:
    ///   - fileName: the name of image file, with which you want to store it on firebase storage. The filename can be of your own choice.
    ///   The filename should be in the format of (name.extension) e.g abc.png , user.jpeg etc .
    ///   - image: the message image you just sent (i.e you want to upload)
    ///   - completion: escaping closure/ completion handler, which on success returns URL of the uploaded image , otherwise returns error of type StorageErrors enum.
    
    public func uploadMessageImage(fileName:String , image:UIImage, completion: @escaping (Result<URL,Error>) -> ()) {
        
    
        // get reference to storage
        let storageRef = Self.storage.reference()
        // get the reference of the path , where you want to store the image at firebase storage, here we are storing our image to messsages folder at firebase storage
        let imagePath = storageRef.child("messages/\(fileName)")
        
        // get data in bytes
        let data = image.pngData()
        
        
        // store it
        imagePath.putData(data!, metadata: nil) { (metadata, error) in
            
            // if operation unsuccessful
            if let err = error {
                // return error of type StorageErrors to completion handler closure
                completion(.failure(StorageErrors.failedToUpload))
                print("StorageManager: func: uploadMessage Line 91:", err.localizedDescription)
                
            }
            // if operation unsuccessful
            else {
                // download its URL
                imagePath.downloadURL { (url, error) in
                    
                    // if while downloading , error occurs (i.e either url or error is nil or both are nil)
                    guard let url = url , error == nil  else {
                        // return error to completion handler.
                        completion(.failure(StorageErrors.failedToGetDownloadUrl))
                        return
                    }
                    // else operation was successful
                    print("SM: ",url)
                    // - return url of the image to the completion handler
                    completion(.success(url))
                }
                
            }
            
            
        }
        
      
    }
    
    
    
    /// upload message video to firebase using its local URL and returns its firebase URL
    /// - Parameters:
    ///   - url: url of the video wrt your mac local scope
    ///   - fileName:  the name of video file, with which you want to store it on firebase storage. The filename can be of your own choice.
    ///   The filename should be in the format of (name.mov) e.g abc.mov , user.mov etc .
    ///   - completion: completion handler , which returns the URL wrt to firebase storage , in case of success and returns error in case of failure.
    public func uploadMessageVideo(url:URL , fileName:String, completion: @escaping (Result<URL,Error>) -> ()){
        
        
        // get reference to storage
        let storageRef = Self.storage.reference()
        // get the reference of the path , where you want to store the video at firebase storage, here we are storing our video to message_videos folder at firebase storage.
        let videoPath = storageRef.child("message_videos/\(fileName)")
        
        
        // store it
        videoPath.putFile(from: url) { (metadata, error) in
            
            // if operation unsuccessful
            if let err = error {
                
                // return error of type StorageErrors to completion handler closure
                completion(.failure(StorageErrors.failedToUpload))
                print("StorageManager: func: uploadMessageVideo Line 143:", err.localizedDescription)
                
            }
            // if operation successful
            else {
                
                // download its URL
                videoPath.downloadURL { (url, error) in
                    // if while downloading , error occurs (i.e either url or error is nil or both are nil)
                    guard let url = url , error == nil  else {
                        // return error to completion handler
                        completion(.failure(StorageErrors.failedToGetDownloadUrl))
                        return
                    }
                    
                    // else operation was successful
                    // - return url of the image to the completion handler
                    completion(.success(url))
                }
                
            }
            
            
        }
        
      
    }
    
    
    // MARK: Fetch Operations
    
    /// Downloads image (load it to your given imageView: UIImageView)
    /// - Parameters:
    ///   - url: firebase URL of that image
    ///   - imageView: image view to which the image is to be loaded
    public func downloadImage(url:URL, imageView: UIImageView) {
        
        // This function takes in URL and returns the data residing at this url
        URLSession.shared.dataTask(with: url,completionHandler: { data, _, err in
            
            guard let data = data , err == nil else {
                
                return
            }
            // if data fetched succesfully , load it to the given image view in the parameter
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
            
        }).resume()
        
        
    }
    
    
    
    /// This function get the URL of the file and returns it
    /// - Parameters:
    ///   - path: file path i.e the path wrt to firebase storage
    ///   - completion: completion handler , that returns the url of the file in case of success and returns error in case of failure
    public func downloadURL (for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        // get reference to the firebase storage
        let storageRef = StorageManager.storage.reference()
        // get the reference to the firebase path of the file , according to the given path
        let filePath = storageRef.child(path)
        
        // download the url
        filePath.downloadURL { (url, error) in
            
            // if any of the values are nil , then it means some error occured so
            guard let url = url , error == nil  else {
                // return the error
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            // else all operations were succesful , so return the url.
            completion(.success(url))
        }
    }
    
    
    
}
