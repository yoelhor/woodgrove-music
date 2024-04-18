//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import MSAL
import UIKit

class LoginViewController: UIViewController {
    
    // Sing-in UI elements
    @IBOutlet weak var singInContainer: UIStackView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    // Sing-up UI elements
    @IBOutlet weak var singUpContainer: UIStackView!
    @IBOutlet weak var signUpEmailTextField: UITextField!
    @IBOutlet weak var signUpPasswordTextField: UITextField!
    @IBOutlet weak var signUpReenterTextField: UITextField!
    @IBOutlet weak var signUpNameTextField: UITextField!
    @IBOutlet weak var signUpCountryTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    var verifyCodeViewController: VerifyCodeViewController?
    
    // Prolile UI elements
    @IBOutlet weak var profileContainer: UIStackView!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var accessTokenTextView: UITextView!
    @IBOutlet weak var welcomeTo: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var readClaimsButton: UIButton!
    var WelcomeMessage: String!
    var accessToken: String!
    var Claims = [[String]]()
    
    // Shared UI elements
    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var headerLabel: UILabel!
    
    // MSAL andtive auth variables
    var nativeAuth: MSALNativeAuthPublicClientApplication!
    var accountResult: MSALNativeAuthUserAccountResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // On view load initiate the MSAL library
        do {
            nativeAuth = try MSALNativeAuthPublicClientApplication(
                clientId: Configuration.clientId,
                tenantSubdomain: Configuration.tenantSubdomain,
                challengeTypes: [.OOB, .password]
            )
        } catch {
            print("Unable to initialize MSAL \(error)")
            showResultText("Unable to initialize MSAL")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // When the view will apear chheck the account
        retrieveCachedAccount()
    }
    
    // On start sign-up, show the sign-up container
    @IBAction func readClaimsPressed(_: Any) {
        
        if let url = URL(string: "https://jwt.ms/#access_token=" + self.accessToken), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        
    }
    
    // On start sign-up, show the sign-up container
    @IBAction func signUpStartPressed(_: Any) {
        singInContainer.isHidden = true
        singUpContainer.isHidden = false
        profileContainer.isHidden = true
    }
    
    // On sign-up pressed, start the sign-up flow
    @IBAction func signUpPressed(_: Any) {
        
        // Check if the required fields
        guard let email = signUpEmailTextField.text, let password = signUpPasswordTextField.text else {
            resultTextView.text = "Email or password not set"
            return
        }
        
        var attributes: [String: Any] = [:]
        
        // Set the display name
        if let displayName = signUpNameTextField.text, !displayName.isEmpty {
            attributes["displayName"] = displayName
        }
        
        // Set the country
        if let country = signUpCountryTextField.text, !country.isEmpty {
            attributes["country"] = country
        }
        
        
        
        print("Signing up with email \(email) and password")
        
        showResultText("Signing up...")
        
        nativeAuth.signUp(username: email,
                          password: password,
                          attributes: attributes,
                          delegate: self)
    }
    
    // On sign-in pressed, start the sign-in flow
    @IBAction func signInPressed(_: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            resultTextView.text = "Email or password not set"
            return
        }
        
        print("Signing in with email \(email) and password")
        
        showResultText("Signing in...")
        
        nativeAuth.signIn(username: email, password: password, delegate: self)
    }
    
    // On sign-out pressed, start the sign-out flow
    @IBAction func signOutPressed(_: Any) {
        guard accountResult != nil else {
            print("signOutPressed: Not currently signed in")
            return
        }
        accountResult?.signOut()
        
        accountResult = nil
        
        showResultText("Signed out")
        
        updateUI()
    }
    
    func showResultText(_ text: String) {
        resultTextView.text = text
    }
    
    func updateUI() {
        let signedIn = (accountResult != nil)
        
        signUpButton.isEnabled = !signedIn
        signInButton.isEnabled = !signedIn
        signOutButton.isEnabled = signedIn
        
        // Set the page header
        if (signedIn)
        {
            headerLabel.text = "Your profile"
            singInContainer.isHidden = true
            singUpContainer.isHidden = true
            profileContainer.isHidden = false
        }
        else
        {
            headerLabel.text = "Login"
            singInContainer.isHidden = false
            singUpContainer.isHidden = true
            profileContainer.isHidden = true
        }
    }
    
    func retrieveCachedAccount() {
        accountResult = nativeAuth.getNativeAuthUserAccount()
        accessToken = ""
        
        if let accountResult = accountResult, let homeAccountId = accountResult.account.homeAccountId?.identifier {
            print("Account found in cache: \(homeAccountId)")
            
            accountResult.getAccessToken(delegate: self)
        } else {
            print("No account found in cache")
            
            
            accountResult = nil
            
            showResultText("")
            
            updateUI()
        }
    }
}

// MARK: - Sign Up delegates

// MARK: SignUpStartDelegate

extension LoginViewController: SignUpStartDelegate {
    func onSignUpStartError(error: MSAL.SignUpStartError) {
        if error.isUserAlreadyExists {
            showResultText("Unable to sign up: User already exists")
        } else if error.isInvalidPassword {
            showResultText("Unable to sign up: The password is invalid")
        } else if error.isInvalidUsername {
            showResultText("Unable to sign up: The username is invalid")
        } else {
            showResultText("Unexpected error signing up: \(error.errorDescription ?? "No error description")")
        }
    }
    
    func onSignUpCodeRequired(newState: MSAL.SignUpCodeRequiredState,
                              sentTo _: String,
                              channelTargetType _: MSAL.MSALNativeAuthChannelType,
                              codeLength _: Int) {
        print("SignUpStartDelegate: onSignUpCodeRequired: \(newState)")
        
        showVerifyCodeModal(submitCallback: { [weak self] code in
            guard let self = self else { return }
            
            newState.submitCode(code: code, delegate: self)
        },
                            resendCallback: { [weak self] in
            guard let self = self else { return }
            
            newState.resendCode(delegate: self)
        }, cancelCallback: { [weak self] in
            guard let self = self else { return }
            
            showResultText("Action cancelled")
        })
    }
}

// MARK: SignUpVerifyCodeDelegate

extension LoginViewController: SignUpVerifyCodeDelegate {
    func onSignUpVerifyCodeError(error: MSAL.VerifyCodeError, newState: MSAL.SignUpCodeRequiredState?) {
        if error.isInvalidCode {
            guard let newState = newState else {
                print("Unexpected state. Received invalidCode but newState is nil")
                
                showResultText("Internal error verifying code")
                return
            }
            
            updateVerifyCodeModal(errorMessage: "Invalid code",
                                  submitCallback: { [weak self] code in
                guard let self = self else { return }
                
                newState.submitCode(code: code, delegate: self)
            }, resendCallback: { [weak self] in
                guard let self = self else { return }
                
                newState.resendCode(delegate: self)
            }, cancelCallback: { [weak self] in
                guard let self = self else { return }
                
                showResultText("Action cancelled")
            })
        } else {
            showResultText("Unexpected error verifying code: \(error.errorDescription ?? "No error description")")
            dismissVerifyCodeModal()
        }
    }
    
    func onSignUpCompleted(newState: MSAL.SignInAfterSignUpState) {
        
        showResultText("Signed up successfully!")
        dismissVerifyCodeModal()
        
        newState.signIn(delegate: self)
    }
}

// MARK: SignUpResendCodeDelegate

extension LoginViewController: SignUpResendCodeDelegate {
    
    func onSignUpResendCodeError(error: MSAL.ResendCodeError, newState: MSAL.SignUpCodeRequiredState?) {
        print("SignUpResendCodeDelegate: onSignUpResendCodeError: \(error)")
        showResultText("Unexpected error while requesting new code")
        dismissVerifyCodeModal()
    }
    
    func onSignUpResendCodeCodeRequired(
        newState: MSAL.SignUpCodeRequiredState,
        sentTo _: String,
        channelTargetType _: MSAL.MSALNativeAuthChannelType,
        codeLength _: Int
    ) {
        updateVerifyCodeModal(errorMessage: nil,
                              submitCallback: { [weak self] code in
            guard let self = self else { return }
            
            newState.submitCode(code: code, delegate: self)
        }, resendCallback: { [weak self] in
            guard let self = self else { return }
            
            newState.resendCode(delegate: self)
        }, cancelCallback: { [weak self] in
            guard let self = self else { return }
            
            showResultText("Action cancelled")
        })
    }
}

// MARK: SignInAfterSignUpDelegate

extension LoginViewController: SignInAfterSignUpDelegate {
    
    func onSignInAfterSignUpError(error: MSAL.SignInAfterSignUpError) {
        showResultText("Error signing in after signing up.")
    }
    
    private func onSignInCompleted_2(result: MSAL.MSALNativeAuthUserAccountResult) {
        // User successfully signed in
        result.getAccessToken(delegate: self)
    }
}

// MARK: - Sign In delegates

// MARK: SignInStartDelegate

extension LoginViewController: SignInStartDelegate {
    
    
    func onSignInCompleted(result: MSAL.MSALNativeAuthUserAccountResult) {
        print("Signed in: \(result.account.username ?? "")")
        
        accountResult = result
        
        result.getAccessToken(delegate: self)
    }
    
    func onSignInStartError(error: MSAL.SignInStartError) {
        print("SignInStartDelegate: onSignInStartError: \(error)")
        
        if error.isUserNotFound || error.isInvalidCredentials || error.isInvalidUsername {
            showResultText("Invalid username or password")
        } else {
            showResultText("Error while signing in: \(error.errorDescription ?? "No error description")")
        }
    }
}

// MARK: - Credentials delegates

// MARK: CredentialsDelegate


extension LoginViewController: CredentialsDelegate {
    
    // In the most common scenario, you receive a call to this method indicating
    // that the user obtained an access token.
    func onAccessTokenRetrieveCompleted(result: MSALNativeAuthTokenResult) {
        
        print("Access Token: \(result.accessToken)")
        
        accessToken = result.accessToken
        showResultText("Signed in.")
        updateUI()
        
        getClaims(accessToken: result.accessToken)
    }
    
    // Invokes a REST API to decode the access token and get the claims
    func getClaims(accessToken: String)
    {

        var request = URLRequest(url: URL(string: "https://api.woodgrovedemo.com/jwt")!)
        
        //HTTP Headers
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // HTTP rerquest body
        do {
            let parameters = ["token": accessToken]
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            
            guard let data = data else {
                print("getClaims is NULL")
                return
            }
            
            do {
                let dictionary = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, String>
                
                // Map the keys and the values into a two dimensional string array
                var arr = [[String]]()
                for (key, value) in dictionary {
                    var row = [String]()
                    row.append(key)
                    row.append(value)
                    arr.append(row)
                }
                
                self.Claims = arr
                self.WelcomeMessage = dictionary["name"]!
                
                // Show the welcome message
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    print("Timer fired!")
                    self.welcomeTo.text = self.WelcomeMessage
                    self.tableView.reloadData()
                }
            } catch {
                print ("Error related to the REST API data")
                self.WelcomeMessage = "";
            }
        })
        
        task.resume()
    }
    
    // MSAL notifies the delegate that the sign-in operation resulted in an error.
    func onAccessTokenRetrieveError(error: MSAL.RetrieveAccessTokenError) {
        showResultText("Error retrieving access token: \(error.errorDescription ?? "No error description")")
    }
}

// MARK: - Verify Code modal methods

extension LoginViewController {
    func showVerifyCodeModal(
        submitCallback: @escaping (_ code: String) -> Void,
        resendCallback: @escaping () -> Void,
        cancelCallback: @escaping () -> Void
    ) {
        verifyCodeViewController = storyboard?.instantiateViewController(
            withIdentifier: "VerifyCodeViewController") as? VerifyCodeViewController
        
        guard let verifyCodeViewController = verifyCodeViewController else {
            print("Error creating Verify Code view controller")
            return
        }
        
        updateVerifyCodeModal(errorMessage: nil,
                              submitCallback: submitCallback,
                              resendCallback: resendCallback,
                              cancelCallback: cancelCallback)
        
        present(verifyCodeViewController, animated: true)
    }
    
    func updateVerifyCodeModal(
        errorMessage: String?,
        submitCallback: @escaping (_ code: String) -> Void,
        resendCallback: @escaping () -> Void,
        cancelCallback: @escaping () -> Void
    ) {
        guard let verifyCodeViewController = verifyCodeViewController else {
            return
        }
        
        if let errorMessage = errorMessage {
            verifyCodeViewController.errorLabel.text = errorMessage
        }
        
        verifyCodeViewController.onSubmit = { code in
            DispatchQueue.main.async {
                submitCallback(code)
            }
        }
        
        verifyCodeViewController.onResend = {
            DispatchQueue.main.async {
                resendCallback()
            }
        }
        
        verifyCodeViewController.onCancel = {
            DispatchQueue.main.async {
                cancelCallback()
            }
        }
    }
    
    func dismissVerifyCodeModal() {
        guard verifyCodeViewController != nil else {
            print("Unexpected error: Verify Code view controller is nil")
            return
        }
        
        dismiss(animated: true)
        verifyCodeViewController = nil
        
    }
}

extension LoginViewController: UITableViewDelegate
{
    // Occurs when a row (song) is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected a song")
    }
}

extension LoginViewController: UITableViewDataSource
{
    // Returns the number of rows in the table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return Claims.count
    }
    
    // Insert a cell in a particular location of the table.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        
        
        // Set the song name from the list of songs
        cell.label?.text = Claims[indexPath.row][0]
        cell.value?.text = Claims[indexPath.row][1]
        
        return cell
    }
}