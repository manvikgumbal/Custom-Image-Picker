//
//  NetworkInterface.swift
//  BygApp
//
//  Created by Manish Gumbal on 26/10/2016.
//  Copyright © 2016 Manish Gumbal. All rights reserved.
//

import Foundation
import Alamofire

typealias JSONDictionary = [String:Any]
typealias JSONArray = [JSONDictionary]
typealias APIServiceSuccessCallback = ((Any?) -> ())
typealias APIServiceFailureCallback = ((NetworkErrorReason?, NSError?) -> ())
typealias JSONArrayResponseCallback = ((JSONArray?) -> ())
typealias JSONDictionaryResponseCallback = ((JSONDictionary?) -> ())


public enum NetworkErrorReason: Error {
    case FailureErrorCode(code: Int, message: String)
    case InternetNotReachable
    case UnAuthorizedAccess
    case Other
}

struct Resource {
    let method: HTTPMethod
    let parameters: [String : Any]?
    let headers: [String:String]?
}

protocol APIService {
    var path: String { get }
    var resource: Resource { get }
}

extension APIService {
    
    /**
     Method which needs to be called from the respective model class.
     - parameter successCallback:   successCallback with the JSON response.
     - parameter failureCallback:   failureCallback with ErrorReason, Error description and Error.
     */
    
    func request(isURLEncoded: Bool = false, success: @escaping APIServiceSuccessCallback, failure: @escaping APIServiceFailureCallback) {
        do {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            debugPrint("********************************* API Request **************************************")
            debugPrint("Request URL:\(path)")
            debugPrint("Request resource: \(resource)")
            debugPrint("************************************************************************************")
            
            var encoding: URLEncoding = .default
            if resource.method == .get || resource.method == .head || resource.method == .delete || isURLEncoded{
                encoding = .methodDependent
            }
            Alamofire.request(path, method: resource.method, parameters: resource.parameters, encoding: encoding, headers: resource.headers).validate().responseJSON(completionHandler: { (response) in
                debugPrint("********************************* API Response *************************************")
                debugPrint("\(response.debugDescription)")
                debugPrint("************************************************************************************")
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                switch response.result {
                case .success(let value):
                    success(value as AnyObject?)
                case .failure(let error):
                    self.handleError(response: response, error: error as NSError, callback: failure)
                }
            })
        }
    }
    
    func upload(fileData: Data, success:  @escaping APIServiceSuccessCallback, failure: @escaping APIServiceFailureCallback) {
        do {
            debugPrint("********************************* API Request **************************************")
            debugPrint("Request URL:\(path)")
            debugPrint("Request resource: \(resource)")
            debugPrint("************************************************************************************")
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let urlRequest = urlRequestWithComponents(urlString: path, parameters: resource.parameters, imageData: fileData)
            Alamofire.upload((urlRequest?.1)!, with: (urlRequest?.0)!).uploadProgress(closure: { (progress) in
                print(progress.localizedDescription)
            }).responseJSON(completionHandler: { (response) in
                debugPrint("********************************* API Response *************************************")
                debugPrint("\(response.debugDescription)")
                debugPrint("************************************************************************************")
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                switch response.result {
                case .success(let value):
                    success(value as AnyObject?)
                case .failure(let error):
                    self.handleError(response: response, error: error as NSError, callback: failure)
                }
            })
        }
    }
    
    
    
    //Create Upload Data with Image
    func urlRequestWithComponents(urlString:String, parameters:[String : Any]?, imageData:Data) -> (URLRequestConvertible, Data)? {
        
        // create url request to send
        var mutableURLRequest = URLRequest(url: NSURL(string: urlString)! as URL)
        mutableURLRequest.httpMethod = resource.method.rawValue
        let boundaryConstant = "myRandomBoundary12345";
        let contentType = "multipart/form-data;boundary="+boundaryConstant
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // create upload data to send
        var uploadData = Data()
        
        // add image
        uploadData.append("\r\n--\(boundaryConstant)\r\n".data(using: String.Encoding.utf8)!)
        uploadData.append("Content-Disposition: form-data; name=\"image\"; filename=\"file.png\"\r\n".data(using: String.Encoding.utf8)!)
        uploadData.append("Content-Type: image/png\r\n\r\n".data(using: String.Encoding.utf8)!)
        uploadData.append(imageData as Data)
        
        // add parameters
        for (key, value) in parameters! {
            uploadData.append("\r\n--\(boundaryConstant)\r\n".data(using: String.Encoding.utf8)!)
            uploadData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
        }
        uploadData.append("\r\n--\(boundaryConstant)--\r\n".data(using: String.Encoding.utf8)!)
        do {
            let result = try Alamofire.URLEncoding.default.encode(mutableURLRequest, with: nil)
            return (result, uploadData)
        }
        catch _ {
        }
        return nil
        // return URLRequestConvertible and NSData
    }
    
    
    
    private func handleError(response: DataResponse<Any>?, error: NSError, callback:APIServiceFailureCallback) {
        if let errorCode = response?.response?.statusCode {
            guard let responseJSON = self.JSONFromData(data: (response?.data)! as NSData) else {
                callback(NetworkErrorReason.FailureErrorCode(code: errorCode, message:""), error)
                debugPrint("Couldn't read the data")
                return
            }
            let message = (responseJSON as? NSDictionary)?["err"] as? String ?? "Something went wrong. Please try again."
            callback(NetworkErrorReason.FailureErrorCode(code: errorCode, message: message), error)
        }
        else {
            let customError = NSError(domain: "Network Error", code: error.code, userInfo: error.userInfo)
            print(response?.result.error?.localizedDescription)
            if let errorCode = response?.result.error?.localizedDescription , errorCode == "The request timed out." {
            callback(NetworkErrorReason.InternetNotReachable, customError)
            }
            else {
                callback(NetworkErrorReason.Other, customError)
            }
        }
    }
    
    // Convert from NSData to json object
    private func JSONFromData(data: NSData) -> Any? {
        do {
            return try JSONSerialization.jsonObject(with: data as Data, options: .mutableContainers)
        } catch let myJSONError {
            debugPrint(myJSONError)
        }
        return nil
    }
    
    // Convert from JSON to nsdata
    private func nsdataFromJSON(json: AnyObject) -> NSData?{
        do {
            return try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) as NSData?
        } catch let myJSONError {
            debugPrint(myJSONError)
        }
        return nil;
    }
    
}

