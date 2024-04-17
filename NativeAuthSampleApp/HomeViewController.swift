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

// swiftlint:disable file_length
class HomeViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var welcomeTo: UILabel!
    var WelcomeMessage: String!
    
    let songs = [
        "Born to be wild (Steppenwolf)",
        "I wanna dance with somebody (Whitney Houston)",
        "Livin on a prayer (Bon Jovi)",
        "Beat it (Michael Jackson)",
        "Ace of Spades (Motorhead)",
        "Wake me up before you go-go (Wham!)",
        "What’s Love Got to Do with It (Tina Turner)",
        "Express Yourself (Madonna)",
        "Super Trouper (Abba)",
        "Queen Of Hearts (Juice Newton)",
        "Islands in the stream (Dolly Parton)",
        "Always on my mind (Willie Nelson)",
        "Into the Groove (Madonna)",
        "When doves cry (Prince)",
        "Never gonna give you up (Rick Astley)",
        "Need you tonight (INXS)"
    ]
    
    var nativeAuth: MSALNativeAuthPublicClientApplication!
    
    var verifyCodeViewController: VerifyCodeViewController?
    
    var accountResult: MSALNativeAuthUserAccountResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        do {
            nativeAuth = try MSALNativeAuthPublicClientApplication(
                clientId: Configuration.clientId,
                tenantSubdomain: Configuration.tenantSubdomain,
                challengeTypes: [.OOB]
            )
        } catch {
            
            // TBD: user friendly error message
            print("Unable to initialize MSAL \(error)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        retrieveCachedAccount()
    }
    
    func updateUI() {
        self.tableView.reloadData()
    }
    
    func retrieveCachedAccount() {
                
        accountResult = nativeAuth.getNativeAuthUserAccount()
        if let accountResult = accountResult, let homeAccountId = accountResult.account.homeAccountId?.identifier {
            print("Account found in cache: \(homeAccountId)")
            
            // The getAccessToken(delegate) accepts a delegate parameter and we must implement the required CredentialsDelegate method.
            accountResult.getAccessToken(delegate: self)
        } else {
            print("No account found in cache")
            
            accountResult = nil
            
            // Hide the welcome message
            self.welcomeTo.text = "";
            
            updateUI()
        }
    }
}

extension HomeViewController: UITableViewDelegate
{
    // Occurs when a row (song) is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected  a song")
    }
}

extension HomeViewController: UITableViewDataSource
{
    // Returns the number of rows in the table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    // Insert a cell in a particular location of the table.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        
        // Set the song name from the list of songs
        cell.label?.text = songs[indexPath.row]
        
        // Enable or disable the play button if the user signed-in
        cell.playButton.isEnabled = (accountResult != nil)
        
        return cell
    }
}

extension HomeViewController: CredentialsDelegate {
    
    // In the most common scenario, you receive a call to this method indicating
    // that the user obtained an access token.
    func onAccessTokenRetrieveCompleted(result: MSALNativeAuthTokenResult) {
        
        // MSAL returns the access token, scopes and expiration date for the access token for the account.
        print("Access Token: \(result.accessToken)")
        
        
        
        let url = URL(string: "https://api.woodgrovedemo.com/jwt?token=" + result.accessToken)!
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, String>
                
                self.WelcomeMessage = "  Hey " + json["name"]! + "! songs you love:"
                
                // Show the welcome message
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    print("Timer fired!")
                    self.welcomeTo.text = self.WelcomeMessage
                }
            } catch {
                self.WelcomeMessage = "";
            }
        })
        
        task.resume()
        
        // Update the UI that the user signed-in
        updateUI()
    }
    
    // MSAL notifies the delegate that the sign-in operation resulted in an error.
    func onAccessTokenRetrieveError(error: MSAL.RetrieveAccessTokenError) {
        
        // TBD: user friendly error message
        print("Error retrieving access token: \(error.errorDescription ?? "No error description")")
    }
}

