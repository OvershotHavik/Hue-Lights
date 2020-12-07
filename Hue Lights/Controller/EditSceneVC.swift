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
    fileprivate var hueLights = [HueModel.Light]()
    fileprivate var sceneKey: String?
    fileprivate var sceneLights = [String : HueModel.Lightstates]()
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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getSceneLightStates()

    }
    
    func addChildVC(){
        addChild(subView)
        rootView.addSubview(subView.view)
        subView.view.backgroundColor = .clear
        subView.didMove(toParent: self)
        subView.tableView.dataSource = self
        
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


//MARK: - SubVIew Tableview dataSource
extension EditSceneVC: HueCellDelegate, UITableViewDataSource{
    //change the light list VC's cell's to match what the scene shows, not what is currently on the light
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let rowName = sourceItems[indexPath.row]
        for x in hueResults{
            hueLights.append(contentsOf: x.lights.values)
        }
        let filtered = hueLights.filter({$0.name == rowName})
        for light in filtered{
            var lightXY = [Double]()
            var lightBri = Int()
            for x in hueResults{
                for i in x.lights{
                    if i.value.name == light.name{
                        if let safeXY = sceneLights[i.key]?.xy{
                            lightXY = safeXY
                        }
                        if let safeBri = sceneLights[i.key]?.bri{
                            lightBri = safeBri
                        }
                        if let tag = Int(i.key){
                            cell.onSwitch.tag = tag
                            cell.brightnessSlider.tag = tag
                            cell.btnChangeColor.tag = tag
                        }
                    }
                }
            }
            
            let reachable = light.state.reachable
            //            let sceneLightColor = [Double]()

            let cellData = LightData(lightName: light.name,
                                     isOn: light.state.on,
                                     brightness: Float(light.state.bri),
                                     isReachable: reachable,
//                                     lightColor: ConvertColor.getRGB(xy: light.state.xy, bri: light.state.bri))
                                     lightColor: ConvertColor.getRGB(xy: lightXY, bri: lightBri))
//                                     lightColor: .white) // for testing.. will need to get the light states for the lights in the gorup and udpate them accordingly
            cell.configureCell(LightData: cellData)

            cell.backgroundColor = .clear
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sourceItems.count
    }
    
    func onSwitchToggled(sender: UISwitch) {
        
    }
    
    func brightnessSliderChanged(sender: UISlider) {
        
    }
    
    func changeLightColor(sender: UIButton) {
        
    }
    
    func getSceneLightStates(){
        for x in hueResults{
            for scene in x.scenes{
                if scene.value.name == sceneName{
                    sceneKey = scene.key
                }
            }
        }
        
        
        if let safeSceneKey = sceneKey{
            guard let url = URL(string: "http://\(bridgeIP)/api/\(bridgeUser)/scenes/\(safeSceneKey)") else {return}
            print(url)
            DataManager.get(url: url) { (results) in
                switch results{
                case.success(let data):
                    do {
                        if let JSONString = String(data: data, encoding: String.Encoding.utf8){
                            print(JSONString)
                        }
                        let resultsFromBridge = try JSONDecoder().decode(HueModel.Scenes.self, from: data)

                        if let safeLightStates = resultsFromBridge.lightstates{
                            self.sceneLights = safeLightStates
                        }
                        for light in self.sceneLights{
                            print("light key: \(light.key), light xy: \(light.value.xy)")
                        }
                        
                    }
                    
                case .failure(let e): print("error: \(e)")
                }
            }
            
        }
    }
}
