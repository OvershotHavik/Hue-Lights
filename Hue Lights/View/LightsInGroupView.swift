//
//  LightsInGroupView.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/4/21.
//

import UIKit

protocol GroupDelegate: class{
    func scenesTapped()
    func identifyTapped()
}
class LightsInGroupView: UIView{
    weak var groupDelegate : GroupDelegate?
    var btnScenes: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(HueSender.scenes.rawValue, for: .normal)
        button.addTarget(self, action: #selector(scenesTapped), for: .touchUpInside)
        button.setTitleColor(.label, for: .normal)
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
    //MARK: - Init
    init(){
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - Setup
    func setup(){
        self.backgroundColor = UI.backgroundColor
        self.addSubview(btnScenes)
        self.addSubview(btnIdentify)
        setupConstraints()
    }
    //MARK: - Setup Constraints
    func setupConstraints(){
        let safeArea = safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            btnScenes.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            btnScenes.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            btnScenes.heightAnchor.constraint(equalToConstant: 40),
            
            btnIdentify.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: UI.horizontalSpacing),
            btnIdentify.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: UI.verticalSpacing),
            btnIdentify.trailingAnchor.constraint(equalTo: btnScenes.leadingAnchor, constant: UI.horizontalSpacing),
            btnIdentify.heightAnchor.constraint(equalToConstant: 40),
            
            //Light VC is added via the LightInGroupVC and top starts at safe area + 50
            
            
//            tableView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 50),
//            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    //MARK: - Scenes Tapped
    @objc func scenesTapped(){
        groupDelegate?.scenesTapped()
        /*
        guard let group = showingGroup else {return}
        DataManager.get(baseURL: baseURL,
                        HueSender: .scenes) { results in
            switch results{
            case .success(let data):
                do {
                    let scenesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Scenes>.self, from: data)
                    let scenes = scenesFromBridge.compactMap {$0}
                    let sceneArray = scenes.filter{$0.group == group.id}
                    DispatchQueue.main.async {
                        let sceneList = SceneListVC(baseURL: self.baseURL, group: group, lightsInScene: self.lightsArray, sceneArray: sceneArray)
                        sceneList.title = HueSender.scenes.rawValue
                        self.navigationController?.pushViewController(sceneList, animated: true)
                    }
                } catch let e {
                    print("Error getting scenes: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
 */
    }
    //MARK: - Identify Tapped
    @objc func identifyTapped(){
        groupDelegate?.identifyTapped()
        /*
        print("Identify tapped for Group")
        let httpBody = ["alert" : "select"]
        if let safeGroup = showingGroup{
            DataManager.updateGroup(baseURL: baseURL,
                                    groupID: safeGroup.id,
                                    method: .put,
                                    httpBody: httpBody,
                                    completionHandler: noAlertOnSuccessClosure)
        }
 */
    }
}
