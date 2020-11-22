//
//  DataManager.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/15/20.
//

import UIKit
enum NetworkError: Error{
    case badResponse(URLResponse)
    case badURL(Error)
    case badData(Data)
    case failure(Error)
}
enum HttpMethod: String {
    case get
    case post
    case put
    case patch
    case delete
}
class DataManager{
    static func get(url: URL, completionHandler: @escaping (Result<Data, NetworkError>) throws -> Void){
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error)  in
            guard error == nil else {
                try? completionHandler(.failure(.badURL(error!)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                try? completionHandler(.failure(.badResponse(response!)))
                return
            }
            print("\(httpResponse.statusCode) \(httpResponse.mimeType!)")
            guard let safeData = data else {
                try? completionHandler(.failure(.badData(data!)))
                return
            }
            try? completionHandler(.success(safeData))
        }
        task.resume()
    }
    
    static func put(url: URL, httpBody: [String: Any]){
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: httpBody, options: []){
            URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
                if let httpresponse = response as? HTTPURLResponse{
                    print(httpresponse.statusCode)
                }
                if let data = data{
                    if let JSONString = String(data: data, encoding: String.Encoding.utf8){
                        print(JSONString)
                    }
                }
            }.resume()
        }
    }
}
