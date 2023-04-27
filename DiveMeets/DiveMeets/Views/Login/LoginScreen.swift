//
//  LoginScreen.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 3/28/23.
//

import SwiftUI
import LocalAuthentication

// Checks that for a given SearchType, at least one of the relevant fields has a value, and returns
// true if so. If all relevant fields are empty, returns false
private func checkFields(divemeetsID: String = "",
                         password: String = "") -> Bool {
    return divemeetsID != "" || password != ""
}

struct LoginSearchView: View {
    @Environment(\.colorScheme) var currentMode
    @State private var divemeetsID: String = ""
    @State private var password: String = ""
    @State private var searchSubmitted: Bool = false
    @State var parsedUserHTML: String = ""
    @State var loginSearchSubmitted: Bool = false
    @State var loginSuccessful: Bool = false
    @State var createdKey: Bool = true
    @State private var isUnlocked = false
    
    @ViewBuilder
    var body: some View {
        
        ZStack {
            
            if searchSubmitted {
                LoginUIWebView(divemeetsID: $divemeetsID, password: $password,
                               parsedUserHTML: $parsedUserHTML,
                               loginSearchSubmitted: $loginSearchSubmitted,
                               loginSuccessful: $loginSuccessful)
            }

            (currentMode == .light ? Color.white : Color.black)
                .ignoresSafeArea()

            // Submit button doesn't switch pages in preview, but it works in Simulator
            LoginSearchInputView(createdKey: $createdKey, divemeetsID: $divemeetsID,
                                 password: $password, searchSubmitted: $searchSubmitted,
                                 parsedUserHTML: $parsedUserHTML,
                                 loginSearchSubmitted: $loginSearchSubmitted,
                                 loginSuccessful: $loginSuccessful)
        }
        .onDisappear {
            searchSubmitted = false
        }
        
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Biometric authentication is available, authenticate the user
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Please authenticate to unlock") {
                success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        isUnlocked = true
                    } else {
                        // Authentication failed
                    }
                }
            }
        } else {
            // Biometric authentication is not available
        }
    }
}

struct LoginSearchInputView: View {
    @State private var showError: Bool = false
    @Binding var createdKey: Bool
    @Binding var divemeetsID: String
    @Binding var password: String
    @Binding var searchSubmitted: Bool
    
    @Binding var parsedUserHTML: String
    @Binding var loginSearchSubmitted: Bool
    @Binding var loginSuccessful: Bool

    private let cornerRadius: CGFloat = 30
    
    var body: some View {
        ZStack {
            VStack {
                
                if loginSuccessful {
                    ProfileView(
                        link: "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
                            + divemeetsID, diverID: divemeetsID)
                        .zIndex(1)
                        .offset(y: 90)
                } else {
                    Text("Login")
                        .font(.title)
                        .bold()
                    
                    LoginPageSearchView(divemeetsID: $divemeetsID, password: $password)
                    
                    VStack {
                        Button(action: {
                            // Need to initially set search to false so webView gets recreated
                            searchSubmitted = false
                            // Only submits a search if one of the relevant fields is filled,
                            // otherwise toggles error
                            if checkFields(divemeetsID: divemeetsID,
                                           password: password) {
                                showError = false
                                searchSubmitted = true
                                loginSearchSubmitted = false
                                // set loginSuccessful to true when the login is successful
                                loginSuccessful = true
                                parsedUserHTML = ""
                            } else {
                                showError = true
                                searchSubmitted = false
                                loginSearchSubmitted = false
                                loginSuccessful = false
                                parsedUserHTML = ""
                            }
                        }, label: {
                            Text("Submit")
                                .animation(nil)
                        })
                        .buttonStyle(.bordered)
                        .cornerRadius(cornerRadius)
                        if searchSubmitted && !loginSuccessful {
                            ProgressView()
                        }
                    }
                    if showError {
                        Text("You must enter at least one field to search")
                            .foregroundColor(Color.red)
                        
                    } else {
                        Text("")
                    }
                    
                    Spacer()
                    Spacer()
                    Spacer()
                }
            }
        }
        .onAppear {
            showError = false
        }
    }
}


struct LoginPageSearchView: View {
    @Binding var divemeetsID: String
    @Binding var password: String
    @State private var isPasswordVisible = false
    
    var body: some View {
        VStack {
            HStack {
                Text("DiveMeets ID:")
                    .padding(.leading)
                TextField("DiveMeets ID", text: $divemeetsID)
                    .textContentType(.username)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Image(systemName: "eye.circle")
                    .opacity(0.0)
                    .padding(.trailing)
            }
            HStack {
                Text("Password:")
                    .padding(.leading)
                if isPasswordVisible {
                    TextField("Password", text: $password)
                        .textContentType(.password)
                        .keyboardType(.default)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.circle" : "eye.slash.circle")
                        .foregroundColor(.gray)
                }
                .padding(.trailing)
            }
        }
        .padding()
        .onAppear {
            divemeetsID = ""
            password = ""
        }
    }
}
