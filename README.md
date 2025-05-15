# N2HE iOS PPFV Demo2
This demo demonstrates the use of N2HE with Facial Verification that allows new user to register their facial image for verification in the future. 
For new user, click on the Register button from the login page. Then, take a facial image, set a username (username should only contain alphabets with no spaces in between), and click on REGISTER button. The feature of facial image taken is extracted and encrypted. The encrypted features are sent to the server (run in Docker) for storage in database. 
For registered user, to verify and login, first take a facial image in the login page, and enter the registered username. When the LOGIN button is clicked, the feature of facial image taken is extracted and encrypted. The encrypted features are sent to the server (run in Docker) for verification. The cosine similarity technique is used to perform the evaluation. The output result is encrypted and sent back to the mobile device. Encrypted result will then be decrypted and if verification is successful, user is allowed to login. 

## Prerequisites  
- Xcode >= 15.3 
- iOS >= 17.5
- COCOAPODS (https://cocoapods.org). It can be installed via homebrew:
```
brew install cocoapods
```

## Installation 
1. Download the demo zip from GitHub, or use command 
```
git clone https://github.com/HintSight-Technology/N2HE_iOS_PPFV_Demo2.git
```
2. Download the model to extract features of facial image from [inceptionResnetV1](https://hintsightfhe-my.sharepoint.com/:u:/g/personal/kaiwen_hintsight_com/Ee1qnQIW6HFGkPSJu80gmw8BRzD1Du87ZZPFaSrsh_5UwA?e=s7rzgN), downloaded model should be placed in directory File Resources.
3. The PyTorch C++ library (LibTorch) is installed with [CocoaPods](https://cocoapods.org), run 
```
pod install
```
4. Open ```HintsightFHE.xcworkspace``` in XCode for the demo:
```
open HintsightFHE.xcworkspace
```
