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
class DataManager{
    static func fetchData(url: URL, completionHandler: @escaping (Result<Data, NetworkError>) throws -> Void){
        
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
}
