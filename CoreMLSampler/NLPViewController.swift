//
//  NLPViewController.swift
//  CoreMLSampler
//
//  Created by tanaka.takaaki on 2017/09/11.
//  Copyright © 2017年 kongming. All rights reserved.
//

import UIKit

class NLPViewController: UIViewController {

    @IBOutlet weak var inputText: UITextField!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pushSend(sender: Any) {
        let text = inputText!.text!
        
        switch segmentControl.selectedSegmentIndex {
        case 0:
            let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
            tagger.string = text
            let dominantLanguage = tagger.dominantLanguage
            print("dominantLanguage = \(dominantLanguage ?? "")")
        case 1:
            let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
            tagger.string = text
            let range = NSRange(location: 0, length: text.utf16.count)
            let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
            tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { tag, tokenRange, stop in
                let token = (text as NSString).substring(with: tokenRange)
                // Do something with each token
                print("token = \(token ?? "")")
            }
        case 2:
            let tagger = NSLinguisticTagger(tagSchemes:[.lemma], options: 0)
            tagger.string = text
            let range = NSRange(location: 0, length: text.utf16.count)
            let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
            tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { tag, tokenRange, stop in
                if let lemma = tag?.rawValue {
                    // Do something with each lemma
                    print("lemma = \(lemma ?? "")")
                }
            }
        case 3:
            let tagger = NSLinguisticTagger(tagSchemes:[.nameType], options: 0)
            tagger.string = text
            let range = NSRange(location: 0, length: text.utf16.count)
            let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
            
            let tags: [NSLinguisticTag] = [.personalName, .placeName, .organizationName]
            tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange, stop in
                if let tag = tag, tags.contains(tag) {
                    let name = (text as NSString).substring(with: tokenRange)
                    print("name = \(name ?? "")")
                }
            }
            
        default:
            ()
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
