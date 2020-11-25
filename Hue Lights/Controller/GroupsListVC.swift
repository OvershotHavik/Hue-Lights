//
//  GroupsListVC.swift
//  Hue Lights
//
//  Created by Steve Plavetzky on 11/25/20.
//

import UIKit

class GroupsListVC: ListController{
    private var filtered = [String]()
    private var hueGroups = [HueModel.Groups]()
    private var hueResults = [HueModel]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let delegate = delegate else {
            assertionFailure("Set the delegate")
            return
        }
        filtered = delegate.sourceItems.sorted(by: { $0.lowercased() < $1.lowercased()})
        hueResults = delegate.hueResults
        for x in hueResults{
            hueGroups.append(contentsOf: x.groups.values)
        }
        self.tableView.reloadData()
        setup()
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.cell) as! HueLightsCell
        cell.cellDelegate = self
        let rowName = filtered[indexPath.row]
        let filtered = hueGroups.filter({$0.name == rowName})
        for group in filtered{
            let reachable = group.state.any_on
            let cellData = LightData(lightName: group.name,
                                     isOn: group.state.all_on,
                                     brightness: Float(group.action.bri),
                                     isReachable: reachable,
                                     lightColor: ConvertColor.getRGB(xy: group.action.xy, bri: group.action.bri))
            cell.configureCell(LightData: cellData)
            for x in hueResults{
                for i in x.groups{
                    if i.value.name == group.name{
                        if let tag = Int(i.key){
                            cell.onSwitch.tag = tag
                            cell.brightnessSlider.tag = tag
                            cell.btnChangeColor.tag = tag
    //                        print("tag: \(onSwitch.tag)")
                        }
                    }
                }
            }
        }
        cell.backgroundColor = .clear
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
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(lightNumber)/action") else {return}
        print(url)
        let httpBody = [
            "xy": colorXY,
        ]
        DataManager.put(url: url, httpBody: httpBody)
    }
}

extension GroupsListVC: HueCellDelegate{
    func onSwitchToggled(sender: UISwitch) {
        guard let delegate = delegate else { return}
        print("Sender's Tag: \(sender.tag)")
        let lightNumber = sender.tag
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(lightNumber)/action") else {return}
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
        guard let url = URL(string: "http://\(delegate.bridgeIP)/api/\(delegate.bridgeUser)/groups/\(lightNumber)/action") else {return}
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
