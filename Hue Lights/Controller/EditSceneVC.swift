//
//  EditSceneVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/6/20.
//

import UIKit

class EditSceneVC: UIViewController, ListSelectionControllerDelegate{
    var sourceItems: [String]
    
    var hueResults : [HueModel]
    
    var bridgeIP: String
    
    var bridgeUser: String
    

    
    fileprivate var rootView : EditSceneView!
    fileprivate var subView : LightsListVC!
    fileprivate var sceneName: String
    
    init(sceneName: String, sourceItems: [String], hueResults: [HueModel], bridgeIP: String, bridgeUser: String) {
        self.sceneName = sceneName
        self.sourceItems = sourceItems
        self.hueResults = hueResults
        self.bridgeIP = bridgeIP
        self.bridgeUser = bridgeUser
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        super.loadView()
        rootView = EditSceneView(sceneName: sceneName)
        subView = LightsListVC(showingGroup: false)
        subView.delegate = self
        addChildVC()
        self.view = rootView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Edit Scene"
    }
    
    func addChildVC(){
        addChild(subView)
        rootView.addSubview(subView.view)
        subView.view.backgroundColor = .clear
        subView.didMove(toParent: self)
        
        subView.view.translatesAutoresizingMaskIntoConstraints = false
        let safeArea = rootView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            subView.view.topAnchor.constraint(equalTo: rootView.tfChangeName.bottomAnchor, constant: UI.verticalSpacing),
            subView.view.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            subView.view.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            subView.view.bottomAnchor.constraint(equalTo: rootView.btnSave.topAnchor, constant: -UI.verticalSpacing)
        ])
    }
}

