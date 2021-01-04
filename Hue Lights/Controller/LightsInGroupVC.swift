//
//  LightsInGroupVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 1/4/21.
//

import UIKit


class LightsInGroupVC: UIViewController{
    weak var updateGroupDelegate : UpdateGroups?
    
    lazy var noAlertOnSuccessClosure : (Result<String, NetworkError>) -> Void = {Result in
        DispatchQueue.main.async {
            switch Result{
            case .success(let response):
                if response.contains("success"){
                    //don't display an alert if successful
                } else {
                    Alert.showBasic(title: "Error occurred", message: response, vc: self) // will need changed later
                }
            case .failure(let e): print("Error occurred: \(e)")
            }
        }
    }
    
    fileprivate var rootView : LightsInGroupView!
    fileprivate var subView : LightsListVC!
    fileprivate var baseURL : String
    fileprivate var group : HueModel.Groups
    fileprivate var lightsArray : [HueModel.Light]
    init(baseURL: String, lightsArray: [HueModel.Light], group: HueModel.Groups) {
        self.baseURL = baseURL
        self.lightsArray = lightsArray
        self.group = group
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        rootView = LightsInGroupView()
        rootView.groupDelegate = self
        self.view = rootView
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.editGroup))
        
        subView = LightsListVC(baseURL: baseURL, lightsArray: lightsArray, showingGroup: group)
        addChildVC()
        super.viewDidLoad()
    }
    func addChildVC(){
        addChild(subView)
        rootView.addSubview(subView.view)
        subView.view.backgroundColor = .clear
        subView.didMove(toParent: self)
        
        subView.view.translatesAutoresizingMaskIntoConstraints = false
        let safeArea = rootView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            subView.view.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 50),
            subView.view.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            subView.view.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            subView.view.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -UI.verticalSpacing)
        ])
    }
    //MARK: - View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        DataManager.get(baseURL: baseURL,
                        HueSender: .groups) { results in
            switch results{
            case .success(let data):
                do {
                    let groupsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Groups>.self, from: data)
                    let groups = groupsFromBridge.compactMap{$0}
                    self.updateGroupDelegate?.updateGroupsDS(items: groups)
                } catch let e {
                    print("Error getting Groups: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
        
    }
    //MARK: - objc - EditGroup
    @objc func editGroup(){
        print("edit tapped - in light list vc")
        DataManager.get(baseURL: baseURL,
                        HueSender: .lights) { results in
            switch results{
            case .success(let data):
                do {
                    let lightsFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Light>.self, from: data)
                    let allLightsOnBridge = lightsFromBridge.compactMap{ $0}
                    DispatchQueue.main.async {
                        let editGroupVC = EditGroupVC(baseURL: self.baseURL,
                                                      group: self.group,
                                                      allLightsOnBridge: allLightsOnBridge)
                        //                            editGroupVC.delegate = self
                        editGroupVC.updateTitleDelegate = self
                        editGroupVC.updateLightsDelegate = self
                        editGroupVC.title = "Editing \(self.group.name)"
                        self.navigationController?.pushViewController(editGroupVC, animated: true)
                        
                    }
                } catch let e {
                    print("Error getting lights: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
}

//MARK: - UpdateTitle, UpdateLights

extension LightsInGroupVC: UpdateTitle, UpdateLights{
    func updateTitle(newTitle: String) {
        self.title = newTitle
    }
    
    func updateLightsDS(items: [HueModel.Light]) {
        //        DispatchQueue.main.async {
        //            self.lightsArray = items.sorted(by: {$0.name < $1.name})
        //            self.tableView.reloadData()
        //        }
    }
    
    
}

//MARK: - Root View - Group Delegate
extension LightsInGroupVC: GroupDelegate{
    //MARK: - Scene Tapped
    func scenesTapped() {
        DataManager.get(baseURL: baseURL,
                        HueSender: .scenes) { results in
            switch results{
            case .success(let data):
                do {
                    let scenesFromBridge = try JSONDecoder().decode(DecodedArray<HueModel.Scenes>.self, from: data)
                    let scenes = scenesFromBridge.compactMap {$0}
                    let sceneArray = scenes.filter{$0.group == self.group.id}
                    DispatchQueue.main.async {
                        let sceneList = SceneListVC(baseURL: self.baseURL,
                                                    group: self.group,
                                                    lightsInScene: self.lightsArray,
                                                    sceneArray: sceneArray,
                                                    appOwner: nil)
                        sceneList.title = HueSender.scenes.rawValue
                        self.navigationController?.pushViewController(sceneList, animated: true)
                    }
                } catch let e {
                    print("Error getting scenes: \(e)")
                }
            case .failure(let e): print(e)
            }
        }
    }
    //MARK: - Identify Tapped
    func identifyTapped() {
        print("Identify tapped for Group")
        let httpBody = ["alert" : "select"]
        DataManager.updateGroup(baseURL: baseURL,
                                groupID: group.id,
                                method: .put,
                                httpBody: httpBody,
                                completionHandler: noAlertOnSuccessClosure)
        
    }
    
}
