//
//  LoginScreen.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 3/28/23.
//

import SwiftUI
import LocalAuthentication


/// Checks that for a given SearchType, at least one of the relevant fields has a value, and returns true if so.
/// If all relevant fields are empty, returns false
private func checkFields(divemeetsID: String = "",
                         password: String = "") -> Bool {
    return divemeetsID != "" || password != ""
}

struct LoginSearchView: View {
    @State private var divemeetsID: String = ""
    @State private var password: String = ""
    @State private var searchSubmitted: Bool = false
    @State var parsedUserHTML: String = ""
    @State var loginSearchSubmitted: Bool = false
    @State var loginSuccessful: Bool = false
    @State var createdKey: Bool = true
    @State private var isUnlocked = false
    @State var keyChange: Bool = false
    @Binding var hideTabBar: Bool
    private let keychain = KeychainSwift()
    @ViewBuilder
    var body: some View {
        ZStack{
//            if createdKey || !keyChange {
//                keychain.set(password, forKey: divemeetsID, withAccess: .accessibleAfterFirstUnlock)
//            }
//            if createdKey {
//                VStack {
//                    if isUnlocked {
//                        Text("Hello")
//                        Text(keychain.allKeys)
//                        //put keychain stuff in here
//                    } else {
//                        Text("Please authenticate to sign in")
//                    }
//                }
//                .onAppear(perform: authenticate)
//            }
//                //check biometrics
//                VStack {
//                    if isUnlocked {
//                        Text("Hello")
//                        Text(keychain.allKeys)
//                        //put keychain stuff in here
//                    } else {
//                        Text("Please authenticate to sign in")
//                    }
//                }
//                .onAppear(perform: authenticate)
            
            if searchSubmitted {
                LoginUIWebView(divemeetsID: $divemeetsID, password: $password, parsedUserHTML: $parsedUserHTML, loginSearchSubmitted: $loginSearchSubmitted, loginSuccessful: $loginSuccessful)
            }

            Color.white.ignoresSafeArea()

            /// Submit button doesn't switch pages in preview, but it works in Simulator
            LoginSearchInputView(createdKey: $createdKey, divemeetsID: $divemeetsID, password: $password, searchSubmitted: $searchSubmitted, parsedUserHTML: $parsedUserHTML, loginSearchSubmitted: $loginSearchSubmitted, loginSuccessful: $loginSuccessful, hideTabBar: $hideTabBar)
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
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Please authenticate to unlock") { success, authenticationError in
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
    @Environment(\.colorScheme) var currentMode
    @State private var showError: Bool = false
    @State var fullScreenResults: Bool = false
    @State var resultSelected: Bool = false
    @Binding var createdKey: Bool
    @Binding var divemeetsID: String
    @Binding var password: String
    @Binding var searchSubmitted: Bool
    
    @Binding var parsedUserHTML: String
    @Binding var loginSearchSubmitted: Bool
    @Binding var loginSuccessful: Bool
    @Binding var hideTabBar: Bool
    /// Light gray
    private let deselectedBGColor: Color = Color(red: 0.94, green: 0.94,
                                                 blue: 0.94)
    private let selectedTextColor: Color = Color.white
    private let deselectedTextColor: Color = Color.blue
    
    private let cornerRadius: CGFloat = 30
    private let selectedBGColor: Color = Color.accentColor
    private let grayValue: CGFloat = 0.90
    private let grayValueDark: CGFloat = 0.10
    private let textColor: Color = Color.primary
    private let typeBubbleWidth: CGFloat = 100
    private let typeBubbleHeight: CGFloat = 35
    
    private let typeBGWidth: CGFloat = 40
    
    var body: some View {
        let typeBGColor: Color = currentMode == .light
        ? Color(red: grayValue, green: grayValue, blue: grayValue)
        : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
        let typeBubbleColor: Color = currentMode == .light
        ? Color.white
        : Color.black
        
        ZStack {
            VStack {
                VStack {
                    Text("Login")
                        .font(.title)
                        .bold()
                }
                
                LoginPageSearchView(divemeetsID: $divemeetsID, password: $password)
                
                VStack {
                    Button(action: {
                        /// Need to initially set search to false so webView gets recreated
                        searchSubmitted = false
                        /// Only submits a search if one of the relevant fields is filled, otherwise toggles error
                        if checkFields(divemeetsID: divemeetsID,
                                       password: password) {
                            showError = false
                            searchSubmitted = true
                            loginSearchSubmitted = false
                            loginSuccessful = false
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
            
            if loginSuccessful {
                ZStack (alignment: .topLeading) {
                    VStack {
                        Text("You Logged In!")
                            .onAppear{
                                fullScreenResults = true
                                if !createdKey{
                                    createdKey = true
                                }
                            }
                        Text(String(createdKey))
                    }
                }
                .offset(y: fullScreenResults ? 0 : 350)
                .animation(.linear(duration: 0.2), value: fullScreenResults)
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
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
            }
            HStack {
                Text("Password:")
                    .padding(.leading)
                if isPasswordVisible {
                    TextField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.trailing)
                } else {
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.trailing)
                }
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.circle" : "eye.slash.circle")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .onAppear {
            divemeetsID = ""
            password = ""
        }
    }
}



