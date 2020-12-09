//
//  EditGroupView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/27/20.
//

import UIKit

protocol UpdateItem: class {
    func saveTapped(name: String)
    func editList()
    func deleteTapped(name: String)
}

protocol ApplyToGroup: class{
    func showScenes()
}

class EditItemView: UIView{
    weak var updateGroupDelegate: UpdateItem?
    weak var applyToGroupDelegate: ApplyToGroup?
    fileprivate var itemName : String
    
    lazy var label : UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    lazy var tfChangeName : UITextField = {
       let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = itemName
        textField.backgroundColor = .white
        textField.textAlignment = .center
        textField.textColor = .black
        return textField
    }()
    private var btnEdit: UIButton = {
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
    
    init(itemName: String,  frame: CGRect = .zero)  {
        self.itemName = itemName
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(){
        backgroundColor = UI.backgroundColor
        self.addSubview(tfChangeName)
        self.addSubview(label)
        self.addSubview(btnEdit)
        self.addSubview(btnSave)
        setupConstraints()
    }
    
    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tfChangeName.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            tfChangeName.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            tfChangeName.widthAnchor.constraint(equalToConstant: 150),
            tfChangeName.heightAnchor.constraint(equalToConstant: 35),
            
            label.topAnchor.constraint(equalTo: tfChangeName.bottomAnchor, constant: UI.verticalSpacing),
            label.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            
            btnEdit.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            btnEdit.topAnchor.constraint(equalTo: label.bottomAnchor, constant: UI.verticalSpacing),
            
            
            btnSave.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            btnSave.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -UI.verticalSpacing),
        ])
    }
    
    @objc func saveTapped(){
        print("Save tapped")
        updateGroupDelegate?.saveTapped(name: tfChangeName.text!)
    }
    
    @objc func editLightsTapped(){
        print("edit tapped")
        updateGroupDelegate?.editList()
    }
    @objc func sceneTapped(){
        print("Scene tapped")
        applyToGroupDelegate?.showScenes()
    }
    func updateLabel(text: String){
        DispatchQueue.main.async {
            self.label.text = text
        }
    }
}
