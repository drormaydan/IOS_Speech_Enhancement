//
//  BabbleLabsApi.swift
//  ClearCloud
//
/*
 * Copyright (c) 2018 by BabbleLabs, Inc.  ALL RIGHTS RESERVED.
 * These coded instructions, statements, and computer programs are the
 * copyrighted works and confidential proprietary information of BabbleLabs, Inc.
 * They may not be modified, copied, reproduced, distributed, or disclosed to
 * third parties in any manner, medium, or form, in whole or in part, without
 * the prior written consent of BabbleLabs, Inc.
 */

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
            //print ("BEFORE LOGIN")
            alamoFireManager!.request("\(API_URL)accounts/api/auth/mobileLogin", method: .post, parameters: parameters,
                                      encoding: JSONEncoding.default, headers: nil).validate().responseJSON(completionHandler: {
                                        response in
                                        switch response.result {
                                        case .success:
                                            //print ("SUCCCESS")
                                            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                                                //print("json --> \(utf8Text)")
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
                                            //print ("FAIL")
                                            completionHandler(ServerError.defaultError, nil)
                                        }
                                      })
            
        } else {
            completionHandler(ServerError.noInternet, nil)
        }
    }
    
    
    func login(userId: String, password: String, completionHandler: @escaping (ServerError?, LoginResponse?) -> Void) {
        if let reachability = reachability, reachability.isReachable {
            
            let parameters: Parameters = [
                "userId" : userId,
                "password" : password
            ]
            //print ("BEFORE LOGIN")
            alamoFireManager!.request("\(API_URL)accounts/api/auth/login", method: .post, parameters: parameters,
                                      encoding: JSONEncoding.default, headers: nil).validate().responseJSON(completionHandler: {
                                        response in
                                        switch response.result {
                                        case .success:
                                            //print ("SUCCCESS")
                                            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                                                //print("login json --> \(utf8Text)")
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
    // entitlements/api/entitlementMetadata/

    func entitlements(email:String ,completionHandler: @escaping (ServerError?, EntitlementsResponse?) -> Void) {
        if let reachability = reachability, reachability.isReachable {
            if let sessionToken = sessionToken {
                let parameters: Parameters = [:]
                
                Alamofire.request("\(API_URL)entitlements/api/entitlementMetadata/\(email)", method: .get, parameters: parameters, headers: ["Authorization" : "Bearer \(sessionToken)"]).validate().responseJSON(completionHandler: {
                    response in
                    switch response.result {
                    case .success:
                        if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                           // print("entitlements --> \(utf8Text)")
                            let serverResponse:EntitlementsResponse = EntitlementsResponse(JSONString: utf8Text)!
                            completionHandler(nil, serverResponse)
                        } else {
                            completionHandler(ServerError.defaultError, nil)
                        }
                    case .failure:
                        completionHandler(ServerError.defaultError, nil)
                    }
                })
            }
        } else {
            completionHandler(ServerError.noInternet, nil)
        }
    }
    
    func submitReceipt(apple_request:AppleReceiptRequest, completionHandler: @escaping (ServerError?, LoginResponse?) -> Void) {
        if let reachability = reachability, reachability.isReachable {
            if let sessionToken = sessionToken {
                
                let urlString = "\(API_URL)payments/api/appleReceipt"
                let json = apple_request.toJSONString(prettyPrint: true)

                let url = URL(string: urlString)!
                let jsonData = json!.data(using: .utf8, allowLossyConversion: false)!
                
                var request = URLRequest(url: url)
                request.httpMethod = HTTPMethod.post.rawValue
                request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                request.addValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
                
                alamoFireManager!.request(request).responseJSON(completionHandler: {
                    
                    response in
                    let resp = String(decoding: response.data!, as: UTF8.self)
                    print("RESPONSE -->\(resp)")
                    
                    switch response.result {
                    case .success:
                        if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                            print("submitReceipt json --> \(utf8Text)")
                            let serverResponse:LoginResponse = LoginResponse(JSONString: utf8Text)!
                            completionHandler(nil, serverResponse)

                            /*
                            if let success = serverResponse.success, success {
                                completionHandler(nil, serverResponse)
                            } else {
                                let serverError = ServerError.init(WithMessage: serverResponse.message!)
                                completionHandler(serverError, nil)
                            }*/
                        } else {
                            completionHandler(ServerError.defaultError, nil)
                        }
                    case .failure:
                        //TMP
                        //let resp = ServerResponse()
                        //resp.success = true
                        //completionHandler(nil, resp)
                        
                        completionHandler(ServerError.defaultError, nil)
                    }
                })
            }
        } else {
            completionHandler(ServerError.noInternet, nil)
        }
    }
    
    func convertAudio(filepath: String, email: String, destination: URL, video:Bool, sampleRate:Double?, completion:@escaping ((Bool, ServerError?, Bool) -> Void)) {
        if let reachability = reachability, reachability.isReachable {
            
            print("CONVERT AUDIO \(filepath)")
            
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "api.babblelabs.com"
            urlComponents.path = "/audioEnhancer/api/audio/stream/\(email)"
            
            var queryItems:[URLQueryItem] = []
            if video {
                queryItems.append(URLQueryItem(name: "product", value: "video"))
            }
            if let sampleRate = sampleRate {
                queryItems.append(URLQueryItem(name: "sampleRate", value: "\(sampleRate)"))
            }
            
            if queryItems.count > 0 {
                urlComponents.queryItems = queryItems
            }
            

            guard let url = urlComponents.url else { fatalError("Could not create URL from components") }
            
            // Specify this request as being a POST method
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            // Make sure that we include headers specifying that our request's HTTP body
            // will be JSON encoded
            var headers = request.allHTTPHeaderFields ?? [:]
            headers["Content-Type"] = "audio/m4a"
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
                completion(false, ServerError.readingFile, false)
            }
            // ... and set our request's HTTP body
            
            // Create and run a URLSession data task with our JSON encoded POST request
            //let config = URLSessionConfiguration.default
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 900.0
            sessionConfig.timeoutIntervalForResource = 900.0

            let session = URLSession(configuration: sessionConfig)
            let task = session.dataTask(with: request) { (responseData, response, responseError) in
                guard responseError == nil else {
                    completion(false,ServerError(WithMessage: (responseError?.localizedDescription)!),false )
                    return
                }
                
                let httpresponse = response as! HTTPURLResponse
                print("response \(httpresponse.statusCode)")
                print("response headers \(httpresponse.allHeaderFields)")
                
                if ((httpresponse.statusCode >= 200) && (httpresponse.statusCode < 300)) {
                    
                    
                    print("response data \(responseData)")
                    print("destination \(destination)")
                    
                    
/*
                    // TMP
                    let defaults: UserDefaults = UserDefaults.standard
                    defaults.set(true, forKey: "did_trial")
                    defaults.set(false, forKey: "trial")
                    defaults.synchronize()
                    // LoginManager.shared.logout()
                    completion(false, ServerError.init(WithMessage: "You have exceeded your..."), true)
                    return
*/
                    
                    // APIs usually respond with the data you just sent in your POST request
                    if let data = responseData {
                        
                        do {
                            try data.write(to: destination)
                        } catch {
                            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                            print("Ooops! Something went wrong!")
                            completion(false, ServerError.writingFile, false)
                            return
                        }
                        completion(true,nil,false)
                    } else {
                        completion(false, ServerError.init(WithMessage: ("no readable data received in response")), false)
                    }
                } else if httpresponse.statusCode == 403 {
                    let reason:String = httpresponse.allHeaderFields["X-BabbleLabs-Message"] as! String
                   
                    if let username = LoginManager.shared.getUsername() {
                        
                        BabbleLabsApi.shared.entitlements(email: username) { (error:ServerError?, response:EntitlementsResponse?) in
                            if let response = response {
                                if let unbilledUsageInCents = response.unbilledUsageInCents, let customerDollarLimit = response.customerDollarLimit, let accountListingState = response.accountListingState {
                                    let unbilled:Double = Double(unbilledUsageInCents)/100.0
                                    let limit:Double = Double(customerDollarLimit)
print("unbilled \(unbilled) limit\(limit) reason \(reason)")
                                    if unbilled >= limit && (!accountListingState.contains("Black")) {
                                        completion(false, ServerError.init(WithMessage: reason), true)
                                    } else {
                                        completion(false, ServerError.init(WithMessage: "Sorry, there was an error"), false)
                                    }
                                }
                            }
                        }
                    } else {
                        if reason.contains("You have exceeded your") || reason.contains("You have used your complimentary") {
                            let defaults: UserDefaults = UserDefaults.standard
                            defaults.set(true, forKey: "did_trial")
                            //defaults.set(false, forKey: "trial")
                            defaults.synchronize()
                            // LoginManager.shared.logout()
                            completion(false, ServerError.init(WithMessage: reason), true)
                            return
                        } else {
                            completion(false, ServerError.init(WithMessage: "Sorry, there was an error"), false)
                        }
                    }
                } else {
                    completion(false, ServerError.init(WithMessage: "Sorry, there was an error"), false)
                }
            }
            task.resume()
        } else {
            completion(false, ServerError.noInternet,false)
        }
        
    }
}
