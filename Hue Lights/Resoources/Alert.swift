//
//  Alert.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/29/20.
//

import UIKit
class Alert {
    
    static func showBasic(title: String, message: String, vc: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        vc.present(alert, animated: true)
    }
    
    static func showConfirmDelete(title: String, message: String, vc: UIViewController, completion: @escaping() -> ()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (UIAlertAction) in
            completion() // perform the delete in the VC
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil)) // dismiss the alert
        vc.present(alert, animated: true)
    }
    
    static func showTapAlert(title: String, message: String, vc: UIViewController, completion: @escaping() -> ()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil)) // dismiss the alert
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { (UIAlertAction) in
            completion() // perform the delete in the VC
        }))
        vc.present(alert, animated: true)
    }
    
}
