//
//  ApiSupporter.swift
//  Eco Car
//
//  Created by Sachin Bhandari on 01/07/20.
//  Copyright © 2020 Sachin Bhandari. All rights reserved.
//

import UIKit

class ApiSupporter {
    

    func apiCalls(url: String, parameters: String, complete: @escaping ((String) -> ())) {
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpBody = parameters.data(using: .utf8)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                // check for fundamental networking error
                print("error=\(error!)")
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            
            guard let finalResponse = responseString?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                print("Some error while trimming")
                return
            }
            
            complete(finalResponse)
                        
        }
        task.resume()
        
    }
    
    func uploadImage(parameters: [String : String], fileName: String, image: UIImage, complete: @escaping ((String) -> ())) {
        let url = URL(string: imageUploadUrl)

        let boundary = "Boundary-\(UUID().uuidString)"

        let session = URLSession.shared

        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"

        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
        let data = createBody(parameters: parameters, boundary: boundary, data: image.jpegData(compressionQuality: 0.7)!, mimeType: "image/jpg", filename: fileName)

        
        
        session.uploadTask(with: urlRequest, from: data) { (responseData, response, error) in
            guard let responseData = responseData, error == nil else {
                // check for fundamental networking error
                print("error=\(error!)")
                return
            }
            
            let responseString = String(data: responseData, encoding: .utf8)
            print("responseString: \(responseString)")
            
            guard let finalResponse = responseString?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                print("Some error while trimming")
                return
            }
            
            print("finalResponse: \(finalResponse)")

            complete(finalResponse)
                        
        }.resume()
    }
    
    
    func createBody(parameters: [String: String],
                    boundary: String,
                    data: Data,
                    mimeType: String,
                    filename: String) -> Data {
        let body = NSMutableData()

        let boundaryPrefix = "--\(boundary)\r\n"

        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }

        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))

        return body as Data
    }
}


extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}
