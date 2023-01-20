

import Foundation
import FirebaseStorage
import UIKit

public enum StorageErrors: Error {
    case failedToUpload
    case failedToGetDownloadUrl
}

final class StorageManager {
    
    private static let storage = Storage.storage()
    
    public func uploadImage(fileName:String , image:UIImageView, view:UIViewController) ->  Bool{
        
        var success = true
        // create reference
        let storageRef = StorageManager.storage.reference()
        let imagePath = storageRef.child("images/\(fileName)")
        
        // get data in bytes
        let data = image.image!.pngData()
        
        
        // store it
        imagePath.putData(data!, metadata: nil) { (metadata, error) in
            
            if let err = error {
                
                Utlities.displayError(result: err.localizedDescription, view: view)
                success = false
                print("Error in Uploading File: func 'uploadImage' Line 34 ", err.localizedDescription)
            }
            
            
        }
        
        return success
    }
    
    public func uploadMessageImage(fileName:String , image:UIImage, completion: @escaping (Result<URL,Error>) -> ()){
        
    
        // create reference
        let storageRef = StorageManager.storage.reference()
        let imagePath = storageRef.child("messages/\(fileName)")
        
        // get data in bytes
        let data = image.pngData()
        
        
        // store it
        imagePath.putData(data!, metadata: nil) { (metadata, error) in
            
            if let err = error {
                
                completion(.failure(StorageErrors.failedToUpload))
                print("StorageManager: func: uploadMessage Line 60:", err.localizedDescription)
                
            }else{
                
                imagePath.downloadURL { (url, error) in
                    
                    guard let url = url , error == nil  else {
                        completion(.failure(StorageErrors.failedToGetDownloadUrl))
                        return
                    }
                    
                    completion(.success(url))
                }
                
            }
            
            
        }
        
      
    }
    
    public func uploadMessageVideo(url:URL , fileName:String, completion: @escaping (Result<URL,Error>) -> ()){
        
    
        // create reference
        let storageRef = StorageManager.storage.reference()
        let videoPath = storageRef.child("message_videos/\(fileName)")
        
        
        // store it
        videoPath.putFile(from: url) { (metadata, error) in
            
            if let err = error {
                
                completion(.failure(StorageErrors.failedToUpload))
                print("StorageManager: func: uploadMessageVideo Line 96:", err.localizedDescription)
                
            }else{
                
                videoPath.downloadURL { (url, error) in
                    
                    guard let url = url , error == nil  else {
                        completion(.failure(StorageErrors.failedToGetDownloadUrl))
                        return
                    }
                    
                    completion(.success(url))
                }
                
            }
            
            
        }
        
      
    }
    
    public func downloadFile(url:URL, view:UIViewController, imageView: UIImageView) {
        
        URLSession.shared.dataTask(with: url,completionHandler: { data, _, err in
            
            guard let data = data , err == nil else{
                
                return
            }
            DispatchQueue.main.async{
                imageView.image = UIImage(data: data)
            }
            
        }).resume()
        
        
    }
    
    
    
    public func downloadURL (for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        let storageRef = StorageManager.storage.reference()
        let imagePath = storageRef.child(path)
        
        imagePath.downloadURL { (url, error) in
            
            guard let url = url , error == nil  else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        }
    }
    
    
    
}
