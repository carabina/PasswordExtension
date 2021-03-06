//
//  PasswordExtension.swift
//  PasswordAppExtension-Swift
//
//  Created by Niklas Fahl on 10/19/17.
//

import UIKit
import WebKit

// Note to creators of libraries or frameworks:
// If you include this code within your library, then to prevent potential duplicate symbol
// conflicts for adopters of your library, you should rename the PasswordExtension class.
// You might to so by adding your own project prefix, e.g., MyLibraryPasswordExtension.

public class PasswordExtension {
    
    public static let shared = PasswordExtension()
    
    /**
     Determines if the password extension is available. Allows you to only show the password extension button to those
     that can use it. Of course, you could leave the button enabled and educate users about the virtues of strong, unique
     passwords instead :)
     
     Note that this returns true if any app that supports the generic `org-appextension-feature-password-management` feature
     is installed.
     */
    public func isAvailable() -> Bool {
        guard let extensionUrl = URL(string: extensionPath) else { return false }
        return UIApplication.shared.canOpenURL(extensionUrl)
    }
    
    /**
     Called from your login page, this method will find all available logins for the given urlString. After the user selects
     a login, it is stored into a dictionary and given to your completion handler. Use the password extension keys above to
     extract the needed information and update your UI.
     
     - parameter urlString: Url to search for in the password manager vault.
     - parameter viewController: View controller to present PasswordExtension on.
     - parameter sender: Use if invoked from UIBarButtonItem or UIView.
     - parameter completion: PasswordExtension response with login details or error.
     */
    public func findLogin(for urlString: String, viewController: UIViewController, sender: Any?, completion: @escaping (PasswordExtensionResponse) -> Void) {
        let item = [PasswordExtensionLogin.urlString.key(): urlString]
        
        presentActivityViewController(for: item, viewController: viewController, sender: sender, typeIdentifier: PasswordExtensionActions.findLogin.path(), completion: completion)
    }
    
    /**
     Create a new login and allow the user to generate a new password before saving. The provided urlString should be
     unique to your app or service and be identical to what you pass into the find login method.
     
     Details about the saved login, including the generated password, are stored in a dictionary and given to your completion handler.
     Use the password extension keys above to extract the needed information and update your UI. For example, updating the UI with the
     newly generated password lets the user know their action was successful.
     
     - parameter loginDetails: Login details to be stored in password manager.
     - parameter generatedPasswordOptions: Password generation options to be used by password manager (may not apply to all password managers)
     - parameter viewController: View controller to present PasswordExtension on.
     - parameter sender: Use if invoked from UIBarButtonItem or UIView.
     - parameter completion: PasswordExtension response with login details or error.
     */
    public func storeLogin(for loginDetails: PasswordExtensionLoginDetails, generatedPasswordOptions: PasswordExtensionGeneratedPasswordOptions?, viewController: UIViewController, sender: Any?, completion: @escaping (PasswordExtensionResponse) -> Void) {
        var item: [String: Any] = loginDetails.dictionaryRepresentation()
        if let generatedPasswordOptions = generatedPasswordOptions?.dictionaryRepresentation() {
            item[PasswordExtensionLogin.generatedPasswordOptions.key()] = generatedPasswordOptions
        }
        
        presentActivityViewController(for: item, viewController: viewController, sender: sender, typeIdentifier: PasswordExtensionActions.saveLogin.path(), completion: completion)
    }
    
    /**
     Change the password for an existing login. The provided urlString should be
     unique to your app or service and be identical to what you pass into the find login method. The username must be the one that the user is currently logged in with.
     Details about the saved login, including the newly generated and the old password, are stored in a dictionary and given to your completion handler.
     Use the password extension keys above to extract the needed information and update your UI. For example, updating the UI with the
     newly generated password lets the user know their action was successful.
     
     - parameter loginDetails: Login details to be looked up and changed in password manager.
     - parameter generatedPasswordOptions: Password generation options to be used by password manager (may not apply to all password managers)
     - parameter viewController: View controller to present PasswordExtension on.
     - parameter sender: Use if invoked from UIBarButtonItem or UIView.
     - parameter completion: PasswordExtension response with login details or error.
     */
    public func changePasswordForLogin(for loginDetails: PasswordExtensionLoginDetails, generatedPasswordOptions: PasswordExtensionGeneratedPasswordOptions?, viewController: UIViewController, sender: Any?, completion: @escaping (PasswordExtensionResponse) -> Void) {
        var item: [String: Any] = loginDetails.dictionaryRepresentation()
        if let generatedPasswordOptions = generatedPasswordOptions?.dictionaryRepresentation() {
            item[PasswordExtensionLogin.generatedPasswordOptions.key()] = generatedPasswordOptions
        }
        
        presentActivityViewController(for: item, viewController: viewController, sender: sender, typeIdentifier: PasswordExtensionActions.changePassword.path(), completion: completion)
    }
    
    /**
     Called from your web view controller, this method will show all the saved logins for the active page in the provided web
     view, and automatically fill the HTML form fields.
     
     - parameter webView: Web view invoking PasswordExtension.
     - parameter viewController: View controller to present PasswordExtension on.
     - parameter sender: Use if invoked from UIBarButtonItem or UIView.
     - parameter completion: PasswordExtension response with success boolean or error.
     */
    public func fillLogin(for webView: WKWebView, viewController: UIViewController, sender: Any?, completion: @escaping (PasswordExtensionResponse) -> Void) {
        webView.evaluateJavaScript(PasswordExtension.webViewCollectFieldsScript) { [unowned self] (result, error) in
            guard let result = result as? String else {
                self.callOnMainThread { [unowned self] () in
                    completion(.error(error: self.failedToCollectFieldsError(with: error)))
                }
                return
            }
            
            self.findLoginForWebView(with: webView.url?.absoluteString ?? "", collectedPageDetails: result, webViewController: viewController, sender: sender, webView: webView, completion: completion)
        }
    }
}
