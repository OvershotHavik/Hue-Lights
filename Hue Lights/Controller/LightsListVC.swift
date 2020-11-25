//
//  LightsListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/25/20.
//

import UIKit

class LightsListVC: ListController{
    private var filtered = [String]()
    private var filteredLights = [HueModel.Light]()
    private var hueResults = [HueModel]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        filtered = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
        filteredLights = delegate.hueLights
        hueResults = delegate.hueResults
        self.tableView.reloadData()
        setup()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let rowName = filtered[indexPath.row]
        let filtered = filteredLights.filter({$0.name == rowName})
        for light in filtered{
            let reachable = light.state.reachable
            let cellData = LightData(lightName: light.name,
                                     isOn: light.state.on,
                                     brightness: Float(light.state.bri),
                                     isReachable: reachable,
                                     lightColor: ConvertColor.getRGB(xy: light.state.xy, bri: light.state.bri))
            cell.configureCell(LightData: cellData)
            for x in hueResults{
                for i in x.lights{
                    if i.value.name == light.name{
                        if let tag = Int(i.key){
                            cell.onSwitch.tag = tag
                            cell.brightnessSlider.tag = tag
                            cell.btnChangeColor.tag = tag
                        }
                    }
                }
            }
            cell.backgroundColor = .clear
        }
        return cell
    }
    override func updatLightColor(){
        guard let tempChangeColorButton = tempChangeColorButton else {return}
        guard let delegate = delegate else { return}
        tempChangeColorButton.backgroundColor = pickedColor
        let red = pickedColor.components.red
        let green = pickedColor.components.green
        let blue = pickedColor.components.blue
        let colorXY = ConvertColor.getXY(red: red, green: green, blue: blue)
        let lightNumber = tempChangeColorButton.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
        print(url)
        let httpBody = [
            "xy": colorXY,
        ]
        DataManager.put(url: url, httpBody: httpBody)
    }
}
extension LightsListVC: HueCellDelegate{
    func onSwitchToggled(sender: UISwitch) {
        guard let delegate = delegate else { return}
        print("Sender's Tag: \(sender.tag)")
        let lightNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
        print(url)
        let httpBody = [
            "on": sender.isOn,
        ]
        DataManager.put(url: url, httpBody: httpBody)
    }
    
    func brightnessSliderChanged(sender: UISlider) {
        guard let delegate = delegate else { return}
        print("Brightness slider changed")
        print("Sender's Tag: \(sender.tag)")
        
        let lightNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/lights/\(lightNumber)/state") else {return}
        print(url)
        let httpBody = [
            "bri": Int(sender.value),
        ]
        DataManager.put(url: url, httpBody: httpBody)
        
    }
    func changeLightColor(sender: UIButton) {
        print("change light color tapped")
        selectColor()
        tempChangeColorButton = sender
    }

}
