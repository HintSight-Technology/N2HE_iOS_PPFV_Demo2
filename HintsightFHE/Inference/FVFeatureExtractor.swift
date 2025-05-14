//
//  FVFeatureExtractor.swift
//  HintsightFHE
//
//  Created by Luo Kaiwen on 30/7/24.
//

import UIKit

class FeatureExtractor {
    lazy var module: InferenceModule = {
        let modelName = "traced_inceptionResnetV1"
        
        if let model = Bundle.main.path(forResource: modelName, ofType: "pt") {
            // Ok, found the model file
        } else {
            fatalError("Can't find the model file!")
        }
        
        if let filePath = Bundle.main.path(forResource: modelName, ofType: "pt"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't load InferenceModule!")
        }
    }()
}
