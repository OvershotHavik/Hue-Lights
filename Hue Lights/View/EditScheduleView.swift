//
//  EditScheduleView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/6/21.
//

import UIKit

class EditScheduleView: UIView{
    fileprivate var mainVScroll: UIScrollView = {
       let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    fileprivate var mainVStack: UIStackView = {
       let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = UI.verticalSpacing
        stack.alignment = .center
        return stack
    }()
    fileprivate var tfChangeNameContView = UIView()
    fileprivate lazy var tfChangeName : UITextField = {
       let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = schedule?.name
        textField.backgroundColor = .white
        textField.textAlignment = .center
        textField.textColor = .black
        return textField
    }()
    
    fileprivate var schedule: HueModel.Schedules?
    init(schedule: HueModel.Schedules?) {
        self.schedule = schedule
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(){
        self.backgroundColor = UI.backgroundColor
        self.addSubview(mainVScroll)
        mainVScroll.addSubview(mainVStack)
        // Add tfChangeName
        mainVStack.addArrangedSubview(tfChangeNameContView)
        tfChangeNameContView.addSubview(tfChangeName)
        
        setupConstraints()
    }
    
    func setupConstraints(){
        let safeArea = self.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            mainVScroll.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            mainVScroll.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: UI.horizontalSpacing),
            mainVScroll.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -UI.horizontalSpacing),
            mainVScroll.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -50),
            
            mainVStack.topAnchor.constraint(equalTo: mainVScroll.topAnchor),
            mainVStack.widthAnchor.constraint(equalTo: mainVScroll.widthAnchor),
            mainVStack.bottomAnchor.constraint(equalTo: mainVScroll.bottomAnchor),
//
//            tfChangeName.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            tfChangeName.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            tfChangeName.widthAnchor.constraint(equalToConstant: 150),
            tfChangeName.heightAnchor.constraint(equalToConstant: 35),
        ])
    }
}
