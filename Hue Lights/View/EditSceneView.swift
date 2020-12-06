//
//  EditSceneView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 12/6/20.
//

import UIKit

class EditSceneView: UIView{
    fileprivate var sceneName: String
    private var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    private var stackView: UIStackView = {
        let stack  = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = UI.verticalSpacing
        return stack
    }()
    
    lazy var tfChangeName : UITextField = {
       let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = sceneName
        textField.backgroundColor = .white
        textField.textAlignment = .center
        textField.textColor = .black
        return textField
    }()
    
    private var btnSave : UIButton = {
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
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(tfChangeName)
        addSubview(btnSave)
        
        setupConstraints()
    }
    
    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            scrollView.widthAnchor.constraint(equalTo: safeArea.widthAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -UI.verticalSpacing),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: safeArea.widthAnchor, constant: -20),
            stackView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
        ])
    }
    
    
    @objc func saveTapped(){
        
    }
}
