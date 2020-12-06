//
//  EditSceneView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/6/20.
//

import UIKit

class EditSceneView: UIView{
    fileprivate var sceneName: String

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
    
    init(sceneName: String, frame: CGRect = .zero){
        self.sceneName = sceneName
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(){
        self.backgroundColor = UI.backgroundColor
        addSubview(tfChangeName)
        addSubview(btnSave)
        setupConstraints()
    }
    
    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tfChangeName.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            tfChangeName.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            tfChangeName.widthAnchor.constraint(equalToConstant: 150),
            tfChangeName.heightAnchor.constraint(equalToConstant: 35),

            //Light VC is added via the EditSceneVC where top is tf change name and bottom is btn save
            
            btnSave.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            btnSave.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
        ])
    }
    
    
    @objc func saveTapped(){
        
    }
}
