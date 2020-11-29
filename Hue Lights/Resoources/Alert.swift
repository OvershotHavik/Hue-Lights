//
//  Alert.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/29/20.
//

import UIKit
class Alert {
    
    class func showBasic(title: String, message: String, vc: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        vc.present(alert, animated: true)
    }
}
