//
//  ModelsSelectViewController.swift
//  CoreMLSampler
//
//  Created by tanaka.takaaki on 2017/08/21.
//  Copyright © 2017年 kongming. All rights reserved.
//

import UIKit

class ModelsSelectViewController: UITableViewController {

    private var selectedModel: ModelType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SelectedModel" {
            guard let detailViewController = segue.destination as? ModelDetailViewController else { return }
            detailViewController.modelType = selectedModel
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: "SelectedFace", sender: nil)
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: "SelectedText", sender: nil)
            } else if indexPath.row == 2 {
                performSegue(withIdentifier: "SelectedBarcode", sender: nil)
            } else {
                performSegue(withIdentifier: "SelectedObject", sender: nil)
            }
        } else if indexPath.section == 1 {
            guard let model = ModelType(rawValue: indexPath.row) else { return }
            selectedModel = model
            performSegue(withIdentifier: "SelectedModel", sender: nil)
        } else if indexPath.section == 2 {
            performSegue(withIdentifier: "SelectedNLP", sender: nil)
        } else {
            fatalError("out of index.")
        }
    }

}
