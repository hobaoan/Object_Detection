//
//  ViewController.swift
//  Object_Detection
//
//  Created by Hồ Bảo An on 18/10/2023.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var btnCamera: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func btnCameraTapped(_ sender: Any) {
        performSegue(withIdentifier: "pushCamera", sender: nil)

    }
    

}

