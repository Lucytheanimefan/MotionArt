//
//  ViewController.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/16/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import UIKit
import MediaPlayer
class ViewController: UIViewController {
    
    // "anime" or "motion"
    var option:String! = "motion"
    
    var mediaPicker: MPMediaPickerController?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selectedMusicLabel: UILabel!
    var musicAssetURL:URL!
    
    var selectedARViz:ARVisualization!
    
    var selectedIndex:Int?
    
    let mlConverter = MLConverter()
    
    var mfcc:[Float]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ARVisualizationManager.shared.delegate = self
        ARVisualizationManager.shared.recreateVisualizations()
        
        // Train
//        let genres = ["blues", "classical","disco","hiphop","jazz","metal","pop",
//                      "reggae","rock","country"]
        
//        let genreDict = ["blues":0, "classical":1,"disco":2,"hiphop":3,"jazz":4,"metal":5,"pop":6, "reggae":7,"rock":8, "country":9]
//        let fileManager = FileManager.default
//
//        let myGroup = DispatchGroup()
//        for (_, genre) in genres.enumerated(){
//            print(genre)
//            guard let enumerator:FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: "/Users/lucyzhang/Desktop/genres-project/genres/" + genre) else {
//                return
//            }
//
//            while let element = enumerator.nextObject() as? String {
//                if element.hasSuffix("wav") { // checks the extension
//                    //print(element)
//                    let url = URL(fileURLWithPath: "/Users/lucyzhang/Desktop/genres-project/genres/" + genre + "/" + element)
//                    myGroup.enter()
//                    AudioTransformer.shared.computeMFCC(assetURL: nil, audioFilePath: url) { (mfcc) in
//                        self.mlConverter.appendToExistingSample(curve: mfcc, label: genre)
//                        self.mlConverter.appendSample(curve: mfcc, label: genre)
//                        myGroup.leave()
//                    }
//                }
//            }
//        }
//        myGroup.notify(queue: .main) {
//            self.mlConverter.train()
//        }
//
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if ARVisualizationManager.shared.needsRefresh{
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            ARVisualizationManager.shared.needsRefresh = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addARVisualization(_ sender: UIButton) {
        self.performSegue(withIdentifier: "addVizSegue", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ARViewController{
            vc.option = self.option
            //vc.musicAssetURL = self.musicAssetURL
            vc.ARVizSettings = self.selectedARViz
            vc.mfcc = self.mfcc
        }
        
        if let vc = segue.destination as? NewVisualizationViewController{
            if let viz = self.selectedARViz, let index = self.selectedIndex{
                vc.visualization = viz
                vc.existingCellIndex = index
            }
        }
    }
    
    @IBAction func displayMediaPicker(_ sender: UIButton) {
        self.displayMediaPicker()
    }
    
    func displayMediaPicker(){
        mediaPicker = MPMediaPickerController(mediaTypes: .anyAudio)
        
        if let picker = mediaPicker{
            picker.delegate = self
            view.addSubview(picker.view)
            self.present(picker, animated: true, completion: nil)
        }
        else
        {
            print("Error: Couldn't instantiate media picker")
        }
    }
}


extension ViewController: MPMediaPickerControllerDelegate{
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // Get the file
        let musicItem = mediaItemCollection.items[0]
        self.selectedMusicLabel.text = musicItem.title
        if let assetURL = musicItem.value(forKey: MPMediaItemPropertyAssetURL) as? URL
        {
            self.musicAssetURL = assetURL
            
//            let sema = DispatchSemaphore(value: 0)
//            AudioTransformer.shared.computeMFCC(assetURL: assetURL, audioFilePath: nil, completion: { (mfcc) in
//                print("GOT MFCC DATA!")
//                self.mfcc = mfcc // 26 length
//                //let prediction = self.mlConverter.predict(data: mfcc)
//                sema.signal()
//            })
//            sema.wait()
        }
        
        
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "visualizationCell") as! ARSettingVizTableViewCell
        cell.title.text = ARVisualizationManager.shared.visualizations[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < ARVisualizationManager.shared.visualizations.count else{
            return
        }
        self.selectedARViz = ARVisualizationManager.shared.visualizations[indexPath.row]
        self.selectedARViz.musicAssetURL = self.musicAssetURL
        // Update the object that's stored
        ARVisualizationManager.shared.visualizations[indexPath.row] = self.selectedARViz
        self.performSegue(withIdentifier: "toARView", sender: self)
    }
}

extension ViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ARVisualizationManager.shared.visualizations.count
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete){
            ARVisualizationManager.shared.removeSetting(index: indexPath.row)
        }
        else if (editingStyle == UITableViewCellEditingStyle.insert){
            print("Insert mode")
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) in
            self.selectedARViz = ARVisualizationManager.shared.visualizations[indexPath.row]
            self.selectedIndex = indexPath.row
            self.performSegue(withIdentifier: "addVizSegue", sender: self)
        }
        editAction.backgroundColor = .blue
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
            ARVisualizationManager.shared.removeSetting(index: indexPath.row)
        }
        deleteAction.backgroundColor = .red
        
        return [editAction, deleteAction]
    }
    
}

extension ViewController: ARVisualizationManagerDelegate{
    func onSettingChange() {
        self.tableView.reloadData()
    }
}
