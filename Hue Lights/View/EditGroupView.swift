//
//  EditGroupView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/27/20.
//

import UIKit

protocol UpdateGroup: class {
    func saveTapped(name: String)
    func editLights()
}

protocol editLightsTapped: class{
}

class EditGroupView: UIView{
    weak var updateGroupDelegate: UpdateGroup?
    fileprivate var hueResults : [HueModel]
    fileprivate var groupName : String
    
    lazy var lblListOfLights : UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    lazy var tfGroupName : UITextField = {
       let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = groupName
        textField.backgroundColor = .white
        textField.textAlignment = .center
        textField.textColor = .black
        return textField
    }()
    private var btnEditLights: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Edit Lights In Group", for: .normal)
        button.addTarget(self, action: #selector(editLightsTapped), for: .touchUpInside)
        return button
    }()
    private var btnSave : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.backgroundColor = .systemGreen
        return button
    }()
    
    init(hueResults: [HueModel], groupName: String,  frame: CGRect = .zero)  {
        self.hueResults = hueResults
        self.groupName = groupName
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(){
        backgroundColor = UI.backgroundColor
        self.addSubview(tfGroupName)
        self.addSubview(lblListOfLights)
        self.addSubview(btnEditLights)
        self.addSubview(btnSave)
        setupConstraints()
    }
    
    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tfGroupName.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            tfGroupName.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            tfGroupName.widthAnchor.constraint(equalToConstant: 150),
            tfGroupName.heightAnchor.constraint(equalToConstant: 35),
            
            lblListOfLights.topAnchor.constraint(equalTo: tfGroupName.bottomAnchor, constant: UI.verticalSpacing),
            lblListOfLights.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            
            btnEditLights.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            btnEditLights.topAnchor.constraint(equalTo: lblListOfLights.bottomAnchor, constant: UI.verticalSpacing),
            
            
            
            btnSave.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            btnSave.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -UI.verticalSpacing),
        ])
    }
    
    @objc func saveTapped(){
        print("Save tapped")
        updateGroupDelegate?.saveTapped(name: tfGroupName.text!)
    }
    
    @objc func editLightsTapped(){
        print("edit tapped")
        updateGroupDelegate?.editLights()
    }
    
    func updateListOfLights(text: String){
        DispatchQueue.main.async {
            self.lblListOfLights.text = text
        }
    }
}
