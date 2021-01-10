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
/*
 only works when the enum conforms to string protocol. This would allow the error.localizedDescription to display whatever is set as the string of the error case
extension NetworkError: LocalizedError{
    var errorDescription: String? { return NSLocalizedString(rawValue, comment: "")}
}
 */
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
//MARK: - Get From URL
    static func getFromURL(url: URL, completionHandler: @escaping (Result<Data, NetworkError>) throws -> Void){
        
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
 /*
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
     */
//MARK: - Get
    static func get(baseURL: String, HueSender: HueSender, completionHandler: @escaping (Result<Data, NetworkError>) throws -> Void){
        guard let url = URL(string: baseURL + HueSender.rawValue) else {return}
        print(url)
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
    
//MARK: - Create User
    static func createUser(baseURL: URL, httpBody: [String: Any], completionHandler: @escaping (Result<Data, NetworkError>) throws -> Void){
        var request = URLRequest(url: baseURL)
        request.httpMethod = HttpMethod.post.rawValue
        print(httpBody)
        if let jsonData = try? JSONSerialization.data(withJSONObject: httpBody, options: []){
            URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
                if let httpresponse = response as? HTTPURLResponse{
                    print(httpresponse.statusCode)
                }
                guard let safeData = data else {
                    
                    try? completionHandler(.failure(.badData))
                    return
                }
                if let JSONString = String(data: safeData, encoding: String.Encoding.utf8){
                    print(JSONString)
                }
                try? completionHandler(.success(safeData))
            }.resume()
        }
    }
    
//MARK: - Update Light
    static func updateLight(baseURL: String, lightID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        let light = "/\(lightID)"
        guard let url = URL(string: baseURL + HueSender.lights.rawValue + light  + Destination.state.rawValue) else {return}
        print(url)
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
//MARK: - Search For New Light
    static func searchForNewLights(baseURL: String, completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        guard let url = URL(string: baseURL + HueSender.lights.rawValue) else {return}
        print(url)
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.post.rawValue
//        print(httpBody)
        if let jsonData = try? JSONSerialization.data(withJSONObject: [:], options: []){
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
    
//MARK: - Modify Light
    static func modifyLight(baseURL: String, lightID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        let light = "/\(lightID)"
        guard let url = URL(string: baseURL + HueSender.lights.rawValue + light) else {return}
        print(url)
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
//MARK: - Update Group
    static func updateGroup(baseURL: String, groupID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        let group = "/\(groupID)"
        guard let url = URL(string: baseURL + HueSender.groups.rawValue + group + Destination.action.rawValue) else {return}
        print(url)
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
//MARK: - Modify Group
    static func modifyGroup(baseURL: String, groupID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        let group = "/\(groupID)"
        guard let url = URL(string: baseURL + HueSender.groups.rawValue + group) else {return}
        print(url)
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
//MARK: - Create Group
    static func createGroup(baseURL: String, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        guard let url = URL(string: baseURL + HueSender.groups.rawValue) else {return}
        print(url)
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.post.rawValue
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
    
//MARK: - Update Scene
    static func updateScene(baseURL: String, sceneID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        let scene = "/\(sceneID)"
        guard let url = URL(string: baseURL + HueSender.scenes.rawValue + scene) else {return}
        print(url)
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

//MARK: - Get Scene Light States
    static func getSceneLightStates(baseURL: String, sceneID: String, HueSender: HueSender, completionHandler: @escaping (Result<Data, NetworkError>) throws -> Void){
        let scene = "/\(sceneID)"
        guard let url = URL(string: baseURL + HueSender.rawValue + scene) else {return}
        print(url)
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
//MARK: - Update Light State In Scene
    static func updateLightStateInScene(baseURL: String, sceneID: String, lightID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        let scene = "/\(sceneID)"
        let light = "/\(lightID)"
        guard let url = URL(string: baseURL + HueSender.scenes.rawValue + scene + Destination.lightstates.rawValue + light) else {return}
        print(url)
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
//MARK: - Create New Scene
    static func createNewScene(baseURL: String, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
        guard let url = URL(string: baseURL + HueSender.scenes.rawValue) else {return}
        print(url)
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.post.rawValue
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
    
//MARK: - Update Schedule
        static func updateSchedule(baseURL: String, scheduleID: String, method: HttpMethod, httpBody: [String: Any], completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
            let schedule = "/\(scheduleID)"
            guard let url = URL(string: baseURL + HueSender.schedules.rawValue + schedule) else {return}
            print(url)
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
    //MARK: - Create New Schedule
        static func createNewSchedule(baseURL: String, scheduleData: Data, completionHandler: @escaping (Result<String, NetworkError>) throws -> Void){
            guard let url = URL(string: baseURL + HueSender.schedules.rawValue) else {return}
            print(url)
            var request = URLRequest(url: url)
            request.httpMethod = HttpMethod.post.rawValue
            URLSession.shared.uploadTask(with: request, from: scheduleData) { (data, response, error) in
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
