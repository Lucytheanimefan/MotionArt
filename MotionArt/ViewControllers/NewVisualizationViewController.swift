//
//  NewVisualizationViewController.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/29/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import UIKit
import MediaPlayer

class NewVisualizationViewController: UIViewController {
    
    var visualization = ARVisualization()
    
    var mediaPicker: MPMediaPickerController?
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var boxDimensionsField: UITextField!
    @IBOutlet weak var ringSeparationField: UITextField!
    @IBOutlet weak var numRingsField: UITextField!
    
    @IBOutlet weak var ringRadiusField: UITextField!
    @IBOutlet weak var selectedMusicLabel: UILabel!
    
    @IBOutlet weak var numRingsSlider: UISlider!
    
    @IBOutlet weak var boxDimensionSlider: UISlider!
    @IBOutlet weak var ringSepSlider: UISlider!
    
    @IBOutlet weak var ringRadiusSlider: UISlider!
    
    @IBOutlet weak var animeSwitch: UISwitch!
    @IBOutlet weak var gamifySwitch: UISwitch!
    
    var existingCellIndex:Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        boxDimensionsField.delegate = self
        ringSeparationField.delegate = self
        numRingsField.delegate = self
        ringRadiusField.delegate = self
        
        nameField.text = visualization.name
        numRingsSlider.setValue(Float(visualization.num_rings), animated: true)
        ringSepSlider.setValue(visualization.ring_separation, animated: true)
        boxDimensionSlider.setValue(visualization.box_dimensions, animated: true)
        ringRadiusSlider.setValue(visualization.ring_radius, animated: true)
        
        boxDimensionsField.text = visualization.box_dimensions.description
        ringSeparationField.text = visualization.ring_separation.description
        numRingsField.text = visualization.num_rings.description
        ringRadiusField.text = visualization.ring_radius.description
        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        print("Move view 150 points upward")
        self.view.frame.origin.y = -150 // Move view 150 points upward
    }

    @objc func keyboardWillHide(sender: NSNotification) {
        print("Move view to original position")
        self.view.frame.origin.y = 0 // Move view to original position
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        visualization.name = self.nameField.text
        if let rings = self.numRingsField.text{
            visualization.num_rings = Int(Float(rings)!)
        }
        if let sep = self.ringSeparationField.text{
            visualization.ring_separation = Float(sep)!
        }
        if let box = self.boxDimensionsField.text{
            visualization.box_dimensions = Float(box)!
        }
        if let ringRadius = self.ringRadiusField.text{
            visualization.ring_radius = Float(ringRadius)!
        }
        if let index = existingCellIndex {
            ARVisualizationManager.shared.visualizations[index] = visualization
        }
        else
        {
            ARVisualizationManager.shared.addSetting(setting: visualization)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func switchAction(_ sender: UISwitch) {
        visualization.gamify = sender.isOn
    }
    
    @IBAction func animeSwitchAction(_ sender: UISwitch) {
        visualization.anime = sender.isOn
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        print("Slider value changed")
        if (sender.restorationIdentifier == "numRings")
        {
            let rounded = sender.value.rounded();  //Casting to an int will truncate, round down
            sender.setValue(rounded, animated: true)
            self.numRingsField.text = rounded.description
        }
        else if (sender.restorationIdentifier == "ringSep"){
            self.ringSeparationField.text = sender.value.description
        }
        else if (sender.restorationIdentifier == "boxDimensions"){
            self.boxDimensionsField.text = sender.value.description
        }
        else if (sender.restorationIdentifier == "ringRadius"){
            self.ringRadiusField.text
             = sender.value.description
        }
    }
    
    
}

extension UIControl {
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let inside = super.point(inside: point, with: event)
        if inside != isHighlighted && event?.type == .touches {
            isHighlighted = inside
        }
        return inside
    }
}

extension NewVisualizationViewController: UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return CharacterSet(charactersIn: "0123456789").isSuperset(of: CharacterSet(charactersIn: string))
    }
}
