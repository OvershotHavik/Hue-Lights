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
    case badData
    case failure(Error)
}
enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
enum Destination: String{
    case state = "/state"
    case action = "/action"
    case lightstates = "/lightstates"
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
                try? completionHandler(.failure(.badData))
                return
            }
            try? completionHandler(.success(safeData))
        }
        task.resume()
    }
    static func sendRequest(method: HttpMethod,url: URL, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        print(httpBody)
        if let jsonData = try? JSONSerialization.data(withJSONObject: httpBody, options: []){
            URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
                if let httpresponse = response as? HTTPURLResponse{
                    print(httpresponse.statusCode)
                }
                if let data = data{
                    if let JSONString = String(data: data, encoding: String.Encoding.utf8){
                        print(JSONString)
                        try? completionHandler(.success(JSONString))
                    }
                } else {
                    try? completionHandler(.failure(.badData))
                }
            }.resume()
        }
    }
    static func getTest(baseURL: String, HueSender: HueSender, completionHandler: @escaping (Result<Data, NetworkError>) throws -> Void){
        guard let url = URL(string: baseURL + HueSender.rawValue) else {return}
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
                try? completionHandler(.failure(.badData))
                return
            }
            try? completionHandler(.success(safeData))
        }
        task.resume()
    }
    
    
    
    static func updateLight(baseURL: String, lightID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        let light = "/\(lightID)"
        guard let url = URL(string: baseURL + HueSender.lights.rawValue + light  + Destination.state.rawValue) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        print(httpBody)
        if let jsonData = try? JSONSerialization.data(withJSONObject: httpBody, options: []){
            URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
                if let httpresponse = response as? HTTPURLResponse{
                    print(httpresponse.statusCode)
                }
                if let data = data{
                    if let JSONString = String(data: data, encoding: String.Encoding.utf8){
                        print(JSONString)
                        try? completionHandler(.success(JSONString))
                    }
                } else {
                    try? completionHandler(.failure(.badData))
                }
            }.resume()
        }
    }
    
    static func updateGroup(baseURL: String, groupID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        let group = "/\(groupID)"
        guard let url = URL(string: baseURL + HueSender.groups.rawValue + group + Destination.action.rawValue) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        print(httpBody)
        if let jsonData = try? JSONSerialization.data(withJSONObject: httpBody, options: []){
            URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
                if let httpresponse = response as? HTTPURLResponse{
                    print(httpresponse.statusCode)
                }
                if let data = data{
                    if let JSONString = String(data: data, encoding: String.Encoding.utf8){
                        print(JSONString)
                        try? completionHandler(.success(JSONString))
                    }
                } else {
                    try? completionHandler(.failure(.badData))
                }
            }.resume()
        }
    }
    
    static func updateScene(baseURL: String, sceneID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        let scene = "/\(sceneID)"
        guard let url = URL(string: baseURL + HueSender.scenes.rawValue + scene) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        print(httpBody)
        if let jsonData = try? JSONSerialization.data(withJSONObject: httpBody, options: []){
            URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
                if let httpresponse = response as? HTTPURLResponse{
                    print(httpresponse.statusCode)
                }
                if let data = data{
                    if let JSONString = String(data: data, encoding: String.Encoding.utf8){
                        print(JSONString)
                        try? completionHandler(.success(JSONString))
                    }
                } else {
                    try? completionHandler(.failure(.badData))
                }
            }.resume()
        }
    }
    static func updateLightStateInScene(baseURL: String, sceneID: String, lightID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        let scene = "/\(sceneID)"
        let light = "/\(lightID)"
        guard let url = URL(string: baseURL + HueSender.scenes.rawValue + scene + Destination.lightstates.rawValue + light) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        print(httpBody)
        if let jsonData = try? JSONSerialization.data(withJSONObject: httpBody, options: []){
            URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
                if let httpresponse = response as? HTTPURLResponse{
                    print(httpresponse.statusCode)
                }
                if let data = data{
                    if let JSONString = String(data: data, encoding: String.Encoding.utf8){
                        print(JSONString)
                        try? completionHandler(.success(JSONString))
                    }
                } else {
                    try? completionHandler(.failure(.badData))
                }
            }.resume()
        }
    }
}
