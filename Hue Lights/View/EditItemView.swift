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
    func identifyTapped()
}

protocol ApplyToGroup: class{
    func showScenes()
}

class EditItemView: UIView{
    weak var updateItemDelegate: UpdateItem?
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
    private var btnIdentify: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Identify", for: .normal)
        button.addTarget(self, action: #selector(identifyTapped), for: .touchUpInside)
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
    private var btnDelete : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Delete", for: .normal)
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        button.backgroundColor = .systemRed
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
    //MARK: - Setup
    func setup(){
        backgroundColor = UI.backgroundColor
        self.addSubview(btnIdentify)
        self.addSubview(tfChangeName)
        self.addSubview(label)
        self.addSubview(btnEdit)
        self.addSubview(btnSave)
        self.addSubview(btnDelete)
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
            
            label.topAnchor.constraint(equalTo: tfChangeName.bottomAnchor, constant: UI.verticalSpacing),
            label.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            
            btnEdit.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            btnEdit.topAnchor.constraint(equalTo: label.bottomAnchor, constant: UI.verticalSpacing),
            
            btnSave.heightAnchor.constraint(equalToConstant: 40),
            btnSave.widthAnchor.constraint(equalToConstant: 100),
            btnSave.trailingAnchor.constraint(equalTo: safeArea.centerXAnchor, constant: -UI.horizontalSpacing),
            btnSave.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -UI.verticalSpacing),
            
            btnDelete.heightAnchor.constraint(equalToConstant: 40),
            btnDelete.widthAnchor.constraint(equalToConstant: 100),
            btnDelete.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -UI.verticalSpacing),
            btnDelete.leadingAnchor.constraint(equalTo: safeArea.centerXAnchor, constant: UI.horizontalSpacing),
        ])
    }
    //MARK: - Objc Functions
    @objc func saveTapped(){
        print("Save tapped")
        updateItemDelegate?.saveTapped(name: tfChangeName.text!)
    }
    
    @objc func editLightsTapped(){
        print("edit tapped")
        updateItemDelegate?.editList()
    }
    @objc func sceneTapped(){
        print("Scene tapped")
        applyToGroupDelegate?.showScenes()
    }
    @objc func identifyTapped(){
        print("Identify Tapped")
        updateItemDelegate?.identifyTapped()
    }
    @objc func deleteTapped(){
        print("Delete Tapped")
        updateItemDelegate?.deleteTapped(name: tfChangeName.text!)
    }
    //MARK: - Update Label
    func updateLabel(text: String){
        DispatchQueue.main.async {
            self.label.text = text
        }
    }
}
