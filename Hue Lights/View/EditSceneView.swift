//
//  EditSceneView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/6/20.
//

import UIKit

class EditSceneView: UIView{
    weak var updateSceneDelegate: UpdateItem?

    lazy var tfChangeName : UITextField = {
       let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = sceneName
        textField.backgroundColor = .white
        textField.textAlignment = .center
        textField.textColor = .black
        return textField
    }()
    var btnSave : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.backgroundColor = .systemGreen
        return button
    }()
    private var btnIdentify: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Identify", for: .normal)
        button.addTarget(self, action: #selector(identifyTapped), for: .touchUpInside)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    fileprivate var btnSelectLights : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Select Lights", for: .normal)
        button.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    
    fileprivate var btnDelete : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Delete", for: .normal)
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .systemRed
        return button
   }()
    fileprivate var sceneName: String
    fileprivate var showingGroupScene: Bool
    init(sceneName: String, showingGroupScene: Bool, frame: CGRect = .zero){
        self.sceneName = sceneName
        self.showingGroupScene = showingGroupScene
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - Setup
    func setup(){
        self.backgroundColor = UI.backgroundColor
        addSubview(tfChangeName)
        addSubview(btnIdentify)
        addSubview(btnSave)
        addSubview(btnDelete)
        addSubview(btnSelectLights)
        if showingGroupScene == true{
            btnSelectLights.isHidden = true
        }
        setupConstraints()
    }
    //MARK: - Setup Constraints
    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tfChangeName.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            tfChangeName.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            tfChangeName.widthAnchor.constraint(equalToConstant: 150),
            tfChangeName.heightAnchor.constraint(equalToConstant: 35),
            
            btnIdentify.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: UI.horizontalSpacing),
            btnIdentify.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            btnIdentify.trailingAnchor.constraint(equalTo: tfChangeName.leadingAnchor),
            
            btnSelectLights.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            btnSelectLights.leadingAnchor.constraint(equalTo: tfChangeName.trailingAnchor, constant: UI.horizontalSpacing),
            
            //Light VC is added via the EditSceneVC where top is tf change name bottomCon and bottom is btn save topCon.
            
            btnSave.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            btnSave.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            
            
            btnDelete.leadingAnchor.constraint(equalTo: btnSave.trailingAnchor, constant: UI.horizontalSpacing),
            btnDelete.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
            
        ])
    }
    @objc func editTapped(){
        print("Edit tapped in view")
        updateSceneDelegate?.editList()
    }
    
    @objc func saveTapped(){
        print("Save tapped in view")
        updateSceneDelegate?.saveTapped(name: tfChangeName.text!)
    }
    @objc func deleteTapped(){
        print("Delete tapped in view")
        updateSceneDelegate?.deleteTapped(name: tfChangeName.text!)
    }
    @objc func identifyTapped(){
        print("Identify tapped")
        updateSceneDelegate?.identifyTapped()
    }
}
