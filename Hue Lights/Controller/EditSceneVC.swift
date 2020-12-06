//
//  EditSceneVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/6/20.
//

import UIKit

class EditSceneVC: UIViewController{
    fileprivate var rootView : EditSceneView!
    fileprivate var sceneName: String
    
    init(sceneName: String) {
        self.sceneName = sceneName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        super.loadView()
        rootView = EditSceneView(sceneName: sceneName)
        self.view = rootView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Edit Scene"
    }
}
