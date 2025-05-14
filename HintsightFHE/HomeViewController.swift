//
//  LoginHomeViewController.swift
//  HintsightFHE
//
//  Created by Luo Kaiwen on 21/3/25.
//

import UIKit

class HomeViewController: UIViewController {

    private let welcomePromptLabel = UILabel()
    private var username: String = ""
    private var screenHeight = 0.0
    private var screenWidth = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(hexString: Colors.background.rawValue, alpha: 1) ?? .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .done, target: self, action: #selector(logoutTapped))
        view.addSubviews(welcomePromptLabel)
        
        configureWelcomePromptLabel()
        
    }
    
    init(screenWidth: CGFloat = 0.0, screenHeight: CGFloat = 0.0, username: String = "") {
        super.init(nibName: nil, bundle: nil)
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.username = username
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func logoutTapped(_ sender: Any) {
        let loginVC = LoginViewController()
        navigationController?.pushViewController(loginVC, animated: true)
    }
    
    
    func configureWelcomePromptLabel() {
        welcomePromptLabel.text = "Hi \(username), Welcome Back!"
        welcomePromptLabel.font = UIFont.boldSystemFont(ofSize: 20)
        welcomePromptLabel.textAlignment = .center
        
        welcomePromptLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            welcomePromptLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomePromptLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

}
