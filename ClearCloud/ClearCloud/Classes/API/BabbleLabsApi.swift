//
//  BabbleLabsApi.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/20/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import SwiftyJSON
import ReachabilitySwift

class BabbleLabsApi: NSObject {

    
    var alamoFireManager : SessionManager? // this line
    
    static let shared: BabbleLabsApi = BabbleLabsApi()
    fileprivate let API_URL: String = "https://api.babblelabs.com/"
    let reachability: Reachability?

    var sessionToken: String? {
        get {
            return UserDefaults.standard.string(forKey: "sessionToken")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "sessionToken")
        }
    }
    
    private override init() {
        reachability = Reachability()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 90
        configuration.timeoutIntervalForResource = 90
        alamoFireManager = Alamofire.SessionManager(configuration: configuration) // not in this line
    }
    
    func mobileLogin(userId: String, password: String, completionHandler: @escaping (ServerError?, LoginResponse?) -> Void) {
        if let reachability = reachability, reachability.isReachable {
            
            let parameters: Parameters = [
                "userId" : userId,
                "password" : password
            ]
            print ("BEFORE LOGIN")
            alamoFireManager!.request("\(API_URL)accounts/api/auth/mobileLogin", method: .post, parameters: parameters,
                                      encoding: JSONEncoding.default, headers: nil).validate().responseJSON(completionHandler: {
                                        response in
                                        switch response.result {
                                        case .success:
                                            print ("SUCCCESS")
                                            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                                                print("json --> \(utf8Text)")
                                                let serverResponse:LoginResponse = LoginResponse(JSONString: utf8Text)!
                                                if serverResponse.auth_token != nil {
                                                    completionHandler(nil, serverResponse)
                                                } else {
                                                    let serverError = ServerError.init(WithMessage: "Sorry, there was an error.")
                                                    completionHandler(serverError, nil)
                                                }
                                            } else {
                                                completionHandler(ServerError.defaultError, nil)
                                            }
                                        case .failure:
                                            print ("FAIL")
                                            completionHandler(ServerError.defaultError, nil)
                                        }
                                      })
            
        } else {
            completionHandler(ServerError.noInternet, nil)
        }
    }
    
    
    func convertAudio(filepath: String, email: String, destination: URL, completion:@escaping ((Bool, ServerError?) -> Void)) {
        if let reachability = reachability, reachability.isReachable {
            
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "api.babblelabs.com"
            urlComponents.path = "/audioEnhancer/api/audio/stream/\(email)"
            guard let url = urlComponents.url else { fatalError("Could not create URL from components") }
            
            // Specify this request as being a POST method
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            // Make sure that we include headers specifying that our request's HTTP body
            // will be JSON encoded
            var headers = request.allHTTPHeaderFields ?? [:]
            headers["Content-Type"] = "audio/aac"
            headers["Authorization"] = "Bearer \(sessionToken!)"
            request.allHTTPHeaderFields = headers
            
            // Now let's encode out Post struct into JSON data...
            let file: FileHandle? = FileHandle(forReadingAtPath: filepath)
            
            if file != nil {
                // Read all the data
                let data = file?.readDataToEndOfFile()
                request.httpBody = data
                //print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
                
                // Close the file
                file?.closeFile()
                
            } else {
                completion(false, ServerError.readingFile)
            }
            // ... and set our request's HTTP body
            
            // Create and run a URLSession data task with our JSON encoded POST request
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let task = session.dataTask(with: request) { (responseData, response, responseError) in
                guard responseError == nil else {
                    completion(false,ServerError(WithMessage: (responseError?.localizedDescription)!) )
                    return
                }
                
                let httpresponse = response as! HTTPURLResponse
                print("response \(httpresponse.statusCode)")
                print("response headers \(httpresponse.allHeaderFields)")
                print("response data \(responseData)")
                print("destination \(destination)")
                
                // APIs usually respond with the data you just sent in your POST request
                if let data = responseData {
                    
                    do {
                        try data.write(to: destination)
                    } catch {
                        // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                        print("Ooops! Something went wrong!")
                        completion(false, ServerError.writingFile)
                        return
                    }
                    /*
                     let file: FileHandle? = FileHandle(forWritingAtPath: destinationpath)
                     if file != nil {
                     
                     // Write it to the file
                     file?.write(data)
                     
                     // Close the file
                     file?.closeFile()
                     } else {
                     print("Ooops! Something went wrong!")
                     completion?(false,"error writing file")
                     }*/
                    completion(true,nil)
                } else {
                    print("no readable data received in response")
                }
            }
            task.resume()
        } else {
            completion(false, ServerError.noInternet)
        }
        
    }
}
