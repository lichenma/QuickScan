import Foundation
import Combine
import AWSS3
import FirebaseAuth
import UIKit

class UploadViewModel: ObservableObject {
    @Published var statusViewModel: StatusViewModel?
    @Published var state: AppState
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var showAlert = false
    @Published var downloadAmount: Double = 0.0
    @Published var uploadText: String = "Uploading..."
    @Published var pushWebView = false
    @Published var redirectUrl = "https://relaxed-snyder-a1ac71.netlify.app/edit"
    
    private var userId = Auth.auth().currentUser?.uid
    private var cancellableBag = Set<AnyCancellable>()
    private let authAPI: AuthAPI
    private let url: String
    
    init(authAPI: AuthAPI, state: AppState, url: String) {
        self.authAPI = authAPI
        self.state = state
        self.url = url
        redirectWebsiteUrl()
    }
    
    func redirectWebsiteUrl() {
        // creates url redirect using userid
        if (userId != nil) {
            let userIdString = String(userId!)
            self.redirectUrl = "\("https://relaxed-snyder-a1ac71.netlify.app/edit?id=")\(userIdString)"
        }
    }
    
    func buttonTapped() {
        //handle request and then set to true to show the alert
        self.showAlert = true
    }
    
    func upload() {
        let Url = URL(string: self.url)!
        var uuid = Url.lastPathComponent
        //uploadFileOld(with: "Tragoedia", type: "png")
        uploadVideo(with: self.url, type: "mov")
    }
    
    let bucketName = "quickscanvideoswift"
    var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    
    func uploadFileOld(with resource: String, type: String) {   //1
        let key = "\(resource).\(type)"
        let localImagePath = Bundle.main.path(forResource: resource, ofType: type)!  //2
        let localImageUrl = URL(fileURLWithPath: localImagePath)
        
        let request = AWSS3TransferManagerUploadRequest()!
        request.bucket = bucketName  //3
        request.key = key  //4
        request.body = localImageUrl
        request.acl = .publicReadWrite  //5
        
        //6
        let transferManager = AWSS3TransferManager.default()
        transferManager.upload(request).continueWith(executor: AWSExecutor.mainThread()) { (task) -> Any? in
            if let error = task.error {
                print(error)
            }
            if task.result != nil {   //7
                print("Uploaded \(key)")
                //do any task
            }
            
            return nil
        }
        
    }
    
    func postRequest(uuid: String) {
        let userId = Auth.auth().currentUser?.uid
        // declare the parameter as a dictionary that contains string as key and value combination. considering inputs are valid
        let modifieduuid = uuid.replacingOccurrences(of: ".mov", with: "")
        let parameters: [String: Any] = ["name": self.title, "description": self.description, "user_id": userId ?? "69696969", "uuid": modifieduuid]
        
        // create the url with URL
        let url = URL(string: "https://quickscan.live/collection")! // change server url accordingly
        
        // create the session object
        let session = URLSession.shared
        
        // now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        
        // add headers for the request
        request.addValue("application/json", forHTTPHeaderField: "Content-Type") // change as per server requirements
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            // convert parameters to Data and assign dictionary to httpBody of request
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error)
            return
        }
        
        // create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Post Request Error: \(error)")
                return
            }
            
            // ensure there is valid response code returned from this HTTP response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                print("Invalid Response received from the server")
                return
            }
            
            // ensure there is data returned
            guard let responseData = data else {
                print("nil Data received from the server")
                return
            }
            do {
                // create json object from data or use JSONDecoder to convert to Model stuct
                if let jsonResponse = try JSONSerialization.jsonObject(with: responseData, options: .mutableContainers) as? [String: Any] {
                    // handle json response
                } else {
                    print("data maybe corrupted or in wrong format")
                    throw URLError(.badServerResponse)
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
        // perform the task
        task.resume()
    }
    
    func uploadVideo(with resource: String,type: String){   //1
        
        let key = "\(resource)"
        //let resource = Bundle.main.path(forResource: resource, ofType: type)!
        //let Url = URL(fileURLWithPath: resource)
        let Url = URL(string: key)!
        
        let expression  = AWSS3TransferUtilityUploadExpression()
        var uploaded = false
        let uuid = Url.lastPathComponent
        
        expression.progressBlock = {
            (task: AWSS3TransferUtilityTask, progress: Progress) -> Void in
            print(progress.fractionCompleted)
            self.downloadAmount = progress.fractionCompleted * 100
            //self.uploadText = "Uploading..."
            //                if self.uploadText == "Uploading..." {
            //                   self.uploadText = "Uploading....."
            //                } else if (self.uploadText == "Uploading.....") {
            //                    self.uploadText = "Uploading..."
            //                }
            if progress.isCancelled || progress.isPaused{
                print("cancelled for some reason")
            }
            if progress.isFinished{
                self.uploadText = "Uploaded Succesfully!"//3
                //                self.postRequest(uuid: uuid)
                if (!uploaded) {
                    print("Upload Finished...")
                    self.postRequest(uuid: uuid)
                    uploaded = true
                }
                return
            }
        }
        
        
        expression.setValue("public-read-write", forRequestHeader: "x-amz-acl")   //4
        expression.setValue("public-read-write", forRequestParameter: "x-amz-acl")
        
        completionHandler = { (task:AWSS3TransferUtilityUploadTask, error:NSError?) -> Void in
            if(error != nil){
                print("Failure uploading file")
                
            }else{
                print("Success uploading file")
            }
        } as? AWSS3TransferUtilityUploadCompletionHandlerBlock
        
        let bucketFileName = Url.lastPathComponent
        //5
        AWSS3TransferUtility.default().uploadFile(Url, bucket: bucketName, key: String(bucketFileName), contentType: resource, expression: expression, completionHandler: self.completionHandler).continueWith(block: { (task:AWSTask) -> AnyObject? in
            if(task.error != nil){
                print(task.error)
                print("Error uploading file: \(String(describing: task.error?.localizedDescription))")
            }
            if(task.result != nil){
                print("Starting upload...")
            }
            return nil
        })
    }
    
}

// MARK: - Private helper function
extension UploadViewModel {
    private func resultMapper(with user: User?) -> StatusViewModel {
        if user != nil {
            state.currentUser = user
            return StatusViewModel.uploadSuccessStatus
        } else {
            return StatusViewModel.errorStatus
        }
    }
}
