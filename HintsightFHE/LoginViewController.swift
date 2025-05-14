//
//  MainViewController.swift
//  HintsightFHE
//
//  Created by Luo Kaiwen on 14/3/25.
//

import UIKit
import Combine

class LoginViewController: UIViewController {
    
    let imageView = UIImageView()
    let cameraButton = UIButton()
    let resetButton = HSTintedButton(color: UIColor(hexString: Colors.pink.rawValue, alpha: 1) ?? .systemPink,
                                     title: "RESET", systemImageName: "")
    let loginButton = HSTintedButton(color: UIColor(hexString: Colors.blue.rawValue, alpha: 1) ?? .systemCyan,
                                      title: "LOGIN", systemImageName: "")
    let usernameTextField = HSTextField(text: "enter your username")
    let signupPromptLabel = UILabel()
    let registerButton = UIButton()
    
    public var image: UIImage?
    public var username: String = ""
    private var screenHeight = 0.0
    private var screenWidth = 0.0
    private let inputWidth: CGFloat = 160
    private let inputHeight: CGFloat = 160
    private let baseUrl = "http://<ip_address>:8000"
    private var extractor = FeatureExtractor()
    private var cancellables = Set<AnyCancellable>()
    private var getCompleteFlag = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        screenHeight = UIScreen.main.bounds.height
        screenWidth = UIScreen.main.bounds.width

        self.navigationItem.hidesBackButton = true
        view.backgroundColor = UIColor(hexString: Colors.background.rawValue, alpha: 1) ?? .white
        view.addSubviews(imageView, cameraButton, usernameTextField, resetButton, loginButton, signupPromptLabel, registerButton)
        
        configureImageView()
        configureCameraButton()
        configureUsernameTextField()
        configureResetButton()
        configureLoginButton()
        configureRegisterPromptLabel()
        configureRegisterButton()
        
    }
    
    
    @objc func cameraTapped(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true)
    }
    
    @objc func resetTapped(_ sender: Any) {
        cameraButton.isHidden = false
        resetButton.isEnabled = false
        loginButton.isEnabled = false

        imageView.image = nil
        username = ""
        usernameTextField.text = ""
        usernameTextField.placeholder = "enter your username"
    }
    
    @objc func loginTapped(_ sender: UIButton) {
        if (username.isEmpty) {
            let message = "Please press done after username is entered."
            self.presentHSAlert(title: "Empty Username", message: message, buttonLabel: "OK", titleLabelColor: .systemPink)
        } else {
            self.getCompleteFlag = false
            self.loginButton.isEnabled = false
            self.loginButton.configuration?.image = nil
            self.loginButton.configuration?.title = "LOGINING IN..."
            let dateID = setDateFormat(as: "MM-dd-yyy_HH:mm:ss:SSS")
            
            let resizedImage = image!.resized(to: CGSize(width: inputWidth, height: inputHeight))
            guard var pixelBuffer = resizedImage.normalized() else { return }
            
            guard let rlwePkPath = Bundle.main.path(forResource: "rlwe_pk", ofType: "txt") else {
                fatalError("Can't find rlwe_pk.txt file!")}
            guard let rlweSkPath = Bundle.main.path(forResource: "rlwe_sk", ofType: "txt") else {
                fatalError("Can't find rlwe_sk.txt file!")}

            DispatchQueue.global().async {
                guard let featureVectors = self.extractor.module.imgFeatureExtract(image: &pixelBuffer) else { return }
                guard let encFeatureVectors = self.extractor.module.imgFeatureExtractandEnc(image: &pixelBuffer, pkFilePath: rlwePkPath, mode: "") else {
                    return
                }
                
//                print(encFeatureVectors)
                
                let body = [
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
                            self.loginButton.isEnabled = true
                            self.loginButton.configuration?.title = "LOGIN"
                        }
                        return
                    }
                    
                    let statusCode = (response as? HTTPURLResponse)?.statusCode
                    print(statusCode)
                    if (statusCode == 404) {
                        DispatchQueue.main.async() {
                            self.presentHSAlert(title: "User Not Registered", message: "User \(self.username) is not registered. Please register first.", buttonLabel: "OK", titleLabelColor: .black)
                            self.loginButton.isEnabled = true
                            self.loginButton.configuration?.title = "LOGIN"
                        }
                        return
                    }

                    
                    // ===================== GET REQUEST ========================
                    let urlString = self.baseUrl + "/ios_ppfr/" + self.username + "_" + dateID + ".json"
                    let url = URL(string: urlString)!
                    typealias DataTaskOutput = URLSession.DataTaskPublisher.Output
                    
                    let dataTaskPublisher = URLSession.shared.dataTaskPublisher(for: url)
                        .tryMap({ (dataTaskOutput: DataTaskOutput) -> Result<DataTaskOutput, Error> in
                            guard let httpResponse = dataTaskOutput.response as? HTTPURLResponse else {
                                return .failure(HSNetError.invalidResponse)
                            }
                            
                            print(httpResponse.statusCode)
                            
                            if httpResponse.statusCode == 404 {
                                throw HSNetError.invalidData
                            }
                            
                            return .success(dataTaskOutput)
                        })
                    
                    dataTaskPublisher
                        .catch({ (error: Error) -> AnyPublisher<Result<URLSession.DataTaskPublisher.Output, Error>, Error> in
                            
                            switch error {
                            case HSNetError.invalidData:
                                print("Received a retryable error")
                                return Fail(error: error)
                                    .delay(for: 0.05, scheduler:  DispatchQueue.global())
                                    .eraseToAnyPublisher()
                            default:
                                print("Received a non-retryable error")
                                return Just(.failure(error))
                                    .setFailureType(to: Error.self)
                                    .eraseToAnyPublisher()
                            }
                        })
                            .retry(5)
                            .tryMap({ result in
                                let response = try result.get()
                                let json = try JSONDecoder().decode(UserEncResult.self, from: response.data)
                                print(json)
                                return json
                            })
                                .sink(receiveCompletion:  { _ in
                                    DispatchQueue.main.async {
                                        if (self.getCompleteFlag == false) {
                                            self.presentHSAlert(title: "Something Went Wrong", message: HSNetError.invalidResponse.rawValue, buttonLabel: "OK", titleLabelColor: .black)
                                        }
                                        self.loginButton.isEnabled = true
                                        self.loginButton.configuration?.title = "LOGIN"
                                        print("end of verification...")
                                    }
                                }, receiveValue: { value in
                                    self.getCompleteFlag = true
                                    DispatchQueue.main.async() {
                                        let vector: [Int64] = value.result
//                                        self.encryptedResultString = vector.map{ String($0) }.joined(separator: ",")
                                        let matchResult = self.extractor.module.imgDecrypt(vector: vector.map { NSNumber(value: $0) }, fileAtPath: rlweSkPath)
//                                        self.decryptedResultString = matchResult ?? ""
                                        let result = matchResult?.split(separator: ",").map{ Int($0) }
                                        
                                        if (result![0]! < result![1]!) {
                                            let message = "Facial biometrics is not a match with \(self.username). Please try again!"
                                            self.presentHSAlert(title: "Verification Failed", message: message, buttonLabel: "OK", titleLabelColor: .systemPink)
                                        } else {
                                            let homeVC = HomeViewController(screenWidth: self.screenWidth, screenHeight: self.screenHeight, username: self.username)
                                            self.resetLoginViewController()
                                            self.navigationController?.pushViewController(homeVC, animated: true)
                                        }

                                    }
                     }).store(in: &self.cancellables)
                                
                } //post request
                task.resume()
            }
        }
    }
    
    @objc func signupTapped(_ sender: UIButton) {
        let registerVC = RegisterViewController(screenWidth: self.screenWidth, screenHeight: self.screenHeight)
        resetLoginViewController()
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    
    private func resetLoginViewController() {
        self.cameraButton.isHidden = false
        self.resetButton.isEnabled = false
        self.loginButton.isEnabled = false
        self.imageView.image = nil
        self.username = ""
        self.usernameTextField.text = ""
        self.usernameTextField.placeholder = "enter your username"
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
    
    private func configureLoginButton() {
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        loginButton.isEnabled = false
        
        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: self.screenHeight/37.28), //25
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: self.screenWidth/4.3), //100
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -self.screenWidth/4.3), //-100
            loginButton.heightAnchor.constraint(equalToConstant: self.screenHeight/18.64) //50
        ])
    }
    
    func configureRegisterPromptLabel() {
        signupPromptLabel.text = "Don't have an account?"
        signupPromptLabel.textColor = .label
        signupPromptLabel.textAlignment = .center
        
        signupPromptLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            signupPromptLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: self.screenHeight/40),
            signupPromptLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: self.screenWidth/5),
        ])
    }
    
    func configureRegisterButton() {
        registerButton.addTarget(self, action: #selector(signupTapped), for: .touchUpInside)
        registerButton.configuration = .plain()
        registerButton.configuration?.title = "Register"
        registerButton.configuration?.baseForegroundColor = UIColor(hexString: Colors.orange.rawValue, alpha: 1) ?? .systemOrange
        
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            registerButton.topAnchor.constraint(equalTo: signupPromptLabel.topAnchor),
            registerButton.bottomAnchor.constraint(equalTo: signupPromptLabel.bottomAnchor),
            registerButton.leadingAnchor.constraint(equalTo: signupPromptLabel.trailingAnchor, constant: self.screenWidth/50)
        ])
    }
    
    
}


