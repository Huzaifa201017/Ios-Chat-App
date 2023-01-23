
import Foundation

// enum representing two states
enum ProfileViewModelType {
    case info , logout
}

// model for table view in profile view controller
struct ProfileViewModel {
    
    let viewModelType: ProfileViewModelType     // define the row type , whether its a log out button or some info regarding user
    let title: String                           // title of the row
    let handler: (() -> Void)?                  // completion handler
}
