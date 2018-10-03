//
//  OktaApi.swift
//  ClearCloud
//
//  Created by Boris Katok on 10/3/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import SwiftyJSON
import ReachabilitySwift

class OktaApi: NSObject {
    var alamoFireManager : SessionManager? // this line
    
    static let shared: OktaApi = OktaApi()
    fileprivate let API_URL: String = "https://dev-931723.oktapreview.com/api/v1/"
    let reachability: Reachability?
    
    var sessionToken: String = "00qg6n9qdnpmYGJw0wv-VvgnofA6E03rZylAzAWgKm"
    
    
    private override init() {
        reachability = Reachability()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 90
        configuration.timeoutIntervalForResource = 90
        alamoFireManager = Alamofire.SessionManager(configuration: configuration) // not in this line
    }
    
    func getUser(email: String, completionHandler: @escaping (ServerError?, UserResponse?) -> Void) {
        if let reachability = reachability, reachability.isReachable {
            let parameters: Parameters = [:]
            
            Alamofire.request(API_URL + "users/\(email)", method: .get, parameters: parameters, headers: ["Authorization" : "SSWS \(sessionToken)"]).validate().responseJSON(completionHandler: {
                response in
                switch response.result {
                case .success:
                    if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                        print("okta getUser --> \(utf8Text)")
                        let videoResponse:UserResponse = UserResponse(JSONString: utf8Text)!
                        if (videoResponse.status! == "ACTIVE") {
                            completionHandler(nil, videoResponse)
                        } else {
                            let serverError = ServerError.init(WithMessage: "Okta Error")
                            completionHandler(serverError, nil)
                        }
                    } else {
                        completionHandler(ServerError.defaultError, nil)
                    }
                case .failure:
                    completionHandler(ServerError.defaultError, nil)
                }
            })
            
        } else {
            completionHandler(ServerError.noInternet, nil)
        }
    }


}
