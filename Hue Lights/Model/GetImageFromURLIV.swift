//
//  GetImageFromURL.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/2/20.
//


import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

//loads an image from url and adds it to the cell for ingredients, and stores the value in cache
class GetImageFromURLIV: UIImageView{
    var task: URLSessionDataTask!
    let spinner = UIActivityIndicatorView(style: .large)
    
    func loadImage( from url: URL, Completion: @escaping() -> ()){
        image = nil
        addSpinner()
        if let task = task {
            task.cancel()
        }
        if let imageFromCache = imageCache.object(forKey: url.absoluteString as AnyObject) as? UIImage{
            self.image = imageFromCache
            removeSpinner()
            return
        }
        
        task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data,
                let newImage = UIImage(data: data) else {
//                    print("Couldn't load image from url \(url)")
                    Completion()
                    return
            }
            DispatchQueue.main.async {
                self.image = newImage
                self.removeSpinner()
            }
            imageCache.setObject(newImage, forKey: url.absoluteString as AnyObject)
        }
        task.resume()
    }
    func addSpinner(){
        addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        spinner.startAnimating()
    }
    func removeSpinner(){
        spinner.removeFromSuperview()
    }
}
