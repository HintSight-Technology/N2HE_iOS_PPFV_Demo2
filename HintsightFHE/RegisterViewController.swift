//
//  RegisterViewController.swift
//  HintsightFHE
//
//  Created by Luo Kaiwen on 14/3/25.
//

import UIKit
import Combine

class RegisterViewController: UIViewController {

    let imageView = UIImageView()
    let cameraButton = UIButton()
    let usernameTextField = HSTextField(text: "set username")
    let resetButton = HSTintedButton(color: UIColor(hexString: Colors.pink.rawValue, alpha: 1) ?? .systemPink,
                                     title: "RESET", systemImageName: "")
    let registerButton = HSTintedButton(color: UIColor(hexString: Colors.orange.rawValue, alpha: 1) ?? .systemOrange,
                                      title: "REGISTER", systemImageName: "")
    
    public var image: UIImage?
    public var username: String = ""
    private var screenHeight = 0.0
    private var screenWidth = 0.0
    private let inputWidth: CGFloat = 160
    private let inputHeight: CGFloat = 160
    private let baseUrl = "http://<ip_address>:8000"
    private var extractor = FeatureExtractor()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(hexString: Colors.background.rawValue, alpha: 1) ?? .white
        view.addSubviews(imageView, cameraButton, usernameTextField, resetButton, registerButton)
        
        configureImageView()
        configureCameraButton()
        configureUsernameTextField()
        configureResetButton()
        configureRegisterButton()
        
    }
    
    init(screenWidth: CGFloat = 0.0, screenHeight: CGFloat = 0.0) {
        super.init(nibName: nil, bundle: nil)
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    @objc func cameraTapped(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true)
    }
    
    @objc func resetTapped(_ sender: UIButton) {
        cameraButton.isHidden = false
        resetButton.isEnabled = false
        registerButton.isEnabled = false

        imageView.image = nil
        username = ""
        usernameTextField.text = ""
        usernameTextField.placeholder = "set username"
    }
    
    @objc func registerTapped(_ sender: UIButton) {
        if (username.isEmpty) {
            let message = "Please press done after username is entered."
            self.presentHSAlert(title: "Empty Username", message: message, buttonLabel: "OK", titleLabelColor: .systemPink)
        } else {
            self.registerButton.isEnabled = false
            self.registerButton.configuration?.image = nil
            self.registerButton.configuration?.title = "REGISTERING..."
            let dateID = setDateFormat(as: "MM-dd-yyy_HH:mm:ss:SSS")
            
            let resizedImage = image!.resized(to: CGSize(width: inputWidth, height: inputHeight))
            guard var pixelBuffer = resizedImage.normalized() else { return }
            guard let rlwePkPath = Bundle.main.path(forResource: "rlwe_pk", ofType: "txt") else {
                fatalError("Can't find rlwe_pk.txt file!")}
            
            DispatchQueue.global().async {
                guard let featureVectors = self.extractor.module.imgFeatureExtract(image: &pixelBuffer) else { return }
                guard let encFeatureVectors = self.extractor.module.imgFeatureExtractandEnc(image: &pixelBuffer, pkFilePath: rlwePkPath, mode: "register") else {
                    return
                }
                
//                print(encFeatureVectors)
                
                let body = [
                    "mode": "register",
                    "id": dateID,
                    "name": self.username,
                    "feature_vector": encFeatureVectors
                ] as [String : Any]
                
                // ======================== POST REQUEST ========================
                var request = URLRequest(url: URL(string: self.baseUrl)!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
                
                let task = URLSession.shared.dataTask(with: request) {
                    data, response, error in
                    guard let _ = data, error == nil else {
                        DispatchQueue.main.async() {
                            self.presentHSAlert(title: "Something Went Wrong", message: HSNetError.invalidResponse.rawValue, buttonLabel: "OK", titleLabelColor: .black)
                            self.registerButton.isEnabled = true
                            self.registerButton.configuration?.title = "REGISTER"
                        }
                        return
                    }
                    
                    let statusCode = (response as? HTTPURLResponse)?.statusCode
                    if (statusCode == 200) {
                        DispatchQueue.main.async() {
                            self.presentHSAlert(title: "Registration Successful!", message: "Facial image of user \(self.username) has been registered successfully.", buttonLabel: "OK", titleLabelColor: .systemGreen)
                            self.registerButton.isEnabled = true
                            self.registerButton.configuration?.title = "REGISTER"
                        }
                    } else if (statusCode == 409) {
                        DispatchQueue.main.async() {
                            self.presentHSAlert(title: "Username Already Exists", message: "User \(self.username) has already been registered.", buttonLabel: "OK", titleLabelColor: .systemPink)
                            self.registerButton.isEnabled = true
                            self.registerButton.configuration?.title = "REGISTER"
                        }
                    } else {
                        print("status code: \(statusCode)")
                        DispatchQueue.main.async() {
                            self.presentHSAlert(title: "Something Went Wrong", message: HSNetError.invalidResponse.rawValue, buttonLabel: "OK", titleLabelColor: .systemPink)
                            self.registerButton.isEnabled = true
                            self.registerButton.configuration?.title = "REGISTER"
                        }
                    }

                }
                task.resume()
            }
        }
    }
    
    
    
    private func configureImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 7
        imageView.backgroundColor = UIColor(hexString: Colors.blue.rawValue, alpha: 0.2) ?? .systemGray6
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: self.screenHeight/6.21), //150
            imageView.widthAnchor.constraint(equalToConstant: min(self.screenHeight/2.9, self.screenWidth/1.34)), //320
            imageView.heightAnchor.constraint(equalToConstant: min(self.screenHeight/2.9, self.screenWidth/1.34)) //320
        ])
    }
    
    private func configureCameraButton() {
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        
        let cameraConfig = UIImage.SymbolConfiguration(pointSize: 30)
        cameraButton.configuration = .filled()
        cameraButton.configuration?.baseBackgroundColor = .clear
        cameraButton.configuration?.image = UIImage(systemName: "camera", withConfiguration: cameraConfig)

        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            cameraButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
    }
    
    private func configureUsernameTextField() {
        usernameTextField.delegate = self
        usernameTextField.layer.masksToBounds = true
        usernameTextField.layer.cornerRadius = 7
        usernameTextField.layer.borderWidth = 1
        usernameTextField.backgroundColor = UIColor(hexString: Colors.gray.rawValue, alpha: 1)
        usernameTextField.layer.borderColor = UIColor(hexString: Colors.gray.rawValue, alpha: 1)?.cgColor
        
        NSLayoutConstraint.activate([
            usernameTextField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: self.screenHeight/46.6), //20
            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameTextField.widthAnchor.constraint(equalToConstant: min(self.screenHeight/2.9, self.screenWidth/1.34)), //320
            usernameTextField.heightAnchor.constraint(equalToConstant: self.screenHeight/18.64) //50
        ])
    }
    
    private func configureResetButton() {
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        resetButton.isEnabled = false

        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: self.screenHeight/12), 
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: self.screenWidth/4.3), //100
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -self.screenWidth/4.3), //-100
            resetButton.heightAnchor.constraint(equalToConstant: self.screenHeight/18.64) //50
        ])
    }
    
    private func configureRegisterButton() {
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        registerButton.isEnabled = false
        
        NSLayoutConstraint.activate([
            registerButton.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: self.screenHeight/37.28), //25
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: self.screenWidth/4.3), //100
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -self.screenWidth/4.3), //-100
            registerButton.heightAnchor.constraint(equalToConstant: self.screenHeight/18.64) //50
        ])
    }

}
