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
}
