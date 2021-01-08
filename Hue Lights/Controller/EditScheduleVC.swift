//
//  EditScheduleVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/6/21.
//

import UIKit

class EditScheduleVC: UIViewController{
    fileprivate var rootView : EditScheduleView!
    fileprivate var schedule: HueModel.Schedules?
    
    init(schedule: HueModel.Schedules?) {
        self.schedule = schedule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        super.loadView()
        rootView = EditScheduleView(schedule: schedule)
        self.view = rootView

    }
}
