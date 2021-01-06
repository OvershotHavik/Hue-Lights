//
//  EditScheduleVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/6/21.
//

import UIKit

class EditScheduleVC: UIViewController{
    fileprivate var rootView : EditScheduleView!
    
    override func loadView() {
        rootView = EditScheduleView()
        self.view = rootView
    }
}
