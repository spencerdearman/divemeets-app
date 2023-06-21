//
//  LoginScreen.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 3/28/23.
//

import SwiftUI
import LocalAuthentication

enum LoginField: Int, Hashable, CaseIterable {
    case diveMeetsId
    case passwd
}

// Checks that for a given SearchType, at least one of the relevant fields has a value, and returns
// true if so. If all relevant fields are empty, returns false
private func checkFields(divemeetsID: String = "",
                         password: String = "") -> Bool {
    return divemeetsID != "" && password != ""
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
    @State var loggedIn = false
    
    @ViewBuilder
    var body: some View {
        
        ZStack {
            
            if searchSubmitted {
                LoginUIWebView(divemeetsID: $divemeetsID, password: $password,
                               parsedUserHTML: $parsedUserHTML,
                               loginSearchSubmitted: $loginSearchSubmitted,
                               loginSuccessful: $loginSuccessful, loggedIn: $loggedIn)
            }
            
            // Submit button doesn't switch pages in preview, but it works in Simulator
            LoginSearchInputView(createdKey: $createdKey, divemeetsID: $divemeetsID,
                                 password: $password, searchSubmitted: $searchSubmitted,
                                 parsedUserHTML: $parsedUserHTML,
                                 loginSearchSubmitted: $loginSearchSubmitted,
                                 loginSuccessful: $loginSuccessful, loggedIn: $loggedIn)
        }
        .onDisappear {
            searchSubmitted = false
        }
        
    }
}

struct LoginSearchInputView: View {
    @Environment(\.colorScheme) var currentMode
    @State var showError: Bool = false
    @FocusState private var focusedField: LoginField?
    @State private var errorMessage: Bool = false
    @State var progressView = true
    @Binding var createdKey: Bool
    @Binding var divemeetsID: String
    @Binding var password: String
    @Binding var searchSubmitted: Bool
    @Binding var parsedUserHTML: String
    @Binding var loginSearchSubmitted: Bool
    @Binding var loginSuccessful: Bool
    @Binding var loggedIn: Bool
    private let cornerRadius: CGFloat = 30
    
    var body: some View {
        ZStack {
            (currentMode == .light ? Color.white : Color.black)
                .ignoresSafeArea()
            // Allows the user to hide the keyboard when clicking on the background of the page
                .onTapGesture {
                    focusedField = nil
                }
            
            ZStack {
                GeometryReader { geometry in
                    VStack {
                        ZStack{
                            Circle()
                                .fill(Custom.darkBlue) // Circle color
                                .frame(width: geometry.size.width
                                       * 2.5, height: geometry.size.width * 2.5) // Adjust the size of the circle as desired
                                .position(x: loginSuccessful ? geometry.size.width: geometry.size.width / 2, y: loginSuccessful ? -geometry.size.width * 0.55 : -geometry.size.width * 0.55) // Center the circle
                                .shadow(radius: 15)
                            //.matchedGeometryEffect(id: "sphere1", in: namespace)
                            Circle()
                                .fill(Custom.coolBlue) // Circle color
                                .frame(width: loginSuccessful ? geometry.size.width
                                       * 1.3 : geometry.size.width
                                       * 2.0, height: loginSuccessful ? geometry.size.width * 1.3 : geometry.size.width * 2.0)
                                .position(x: loginSuccessful ? geometry.size.width * 0.8 : geometry.size.width / 2, y: loginSuccessful ? geometry.size.width * 0.6 : -geometry.size.width * 0.55)
                                .shadow(radius: 15)
                            //.matchedGeometryEffect(id: "sphere2", in: namespace)
                            Circle()
                                .fill(Custom.medBlue) // Circle color
                                .frame(width: loginSuccessful ? geometry.size.width
                                       * 1.1 : geometry.size.width
                                       * 1.5, height: loginSuccessful ? geometry.size.width * 1.1 : geometry.size.width * 1.5)
                                .position(x: loginSuccessful ? 0 : geometry.size.width / 2, y: loginSuccessful ? geometry.size.width * 0.65 : -geometry.size.width * 0.55)
                                .shadow(radius: 15)
                            //.matchedGeometryEffect(id: "sphere3", in: namespace)
                        }
                    }
                }
                VStack {
                    if loginSuccessful {
                        LoginProfile(
                            link: "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
                            + divemeetsID, diverID: divemeetsID, loggedIn: $loggedIn, divemeetsID: $divemeetsID, password: $password, searchSubmitted: $searchSubmitted, loginSuccessful: $loginSuccessful, loginSearchSubmitted: $loginSearchSubmitted)
                        .zIndex(1)
                        .offset(y: 90)
                    } else {
                        LoginPageSearchView(showError: $showError, divemeetsID: $divemeetsID, password: $password, searchSubmitted: $searchSubmitted, loginSuccessful: $loginSuccessful, progressView: $progressView, errorMessage: $errorMessage, focusedField: $focusedField)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Button(action: previous) {
                                        Image(systemName: "chevron.up")
                                    }
                                    .disabled(hasReachedStart)
                                    
                                    Button(action: next) {
                                        Image(systemName: "chevron.down")
                                    }
                                    .disabled(hasReachedEnd)
                                    
                                    Spacer()
                                    
                                    Button(action: dismissKeyboard) {
                                        Text("**Done**")
                                    }
                                }
                            }
                    }
                }
            }
        }
        .onAppear {
            showError = false
        }
    }
}


struct LoginPageSearchView: View {
    @Binding var showError: Bool
    @Binding var divemeetsID: String
    @Binding var password: String
    @Binding var searchSubmitted: Bool
    @Binding var loginSuccessful: Bool
    @Binding var progressView: Bool
    @Binding var errorMessage: Bool
    @State private var isPasswordVisible = false
    fileprivate var focusedField: FocusState<LoginField?>.Binding
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private let cornerRadius: CGFloat = 30
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        VStack{
            Spacer()
            Spacer()
            VStack{
                Text("Login")
            }
            .alignmentGuide(.leading) { _ in
                -UIScreen.main.bounds.width / 2 // Align the text to the leading edge of the screen
            }
            .bold()
            .font(.title)
            .padding()
            HStack {
                Text("DiveMeets ID:")
                    .padding(.leading)
                TextField("DiveMeets ID", text: $divemeetsID)
                    .modifier(LoginTextFieldClearButton(text: $divemeetsID,
                                                        fieldType: .diveMeetsId,
                                                        focusedField: focusedField))
                    .textContentType(.username)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .focused(focusedField, equals: .diveMeetsId)
                Image(systemName: "eye.circle")
                    .opacity(0.0)
                    .padding(.trailing)
            }
            HStack {
                Text("Password:")
                    .padding(.leading)
                if isPasswordVisible {
                    TextField("Password", text: $password)
                        .modifier(LoginTextFieldClearButton(text: $password,
                                                            fieldType: .passwd,
                                                            focusedField: focusedField))
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .keyboardType(.default)
                        .textFieldStyle(.roundedBorder)
                        .focused(focusedField, equals: .passwd)
                } else {
                    SecureField("Password", text: $password)
                        .modifier(LoginTextFieldClearButton(text: $password,
                                                            fieldType: .passwd,
                                                            focusedField: focusedField))
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .focused(focusedField, equals: .passwd)
                }
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.circle" : "eye.slash.circle")
                        .foregroundColor(.gray)
                }
                .padding(.trailing)
            }
            
            Button(action: {
                // Need to initially set search to false so webView gets recreated
                searchSubmitted = false
                errorMessage = false
                // Only submits a search if one of the relevant fields is filled,
                // otherwise toggles error
                if checkFields(divemeetsID: divemeetsID,
                               password: password) {
                    showError = false
                    searchSubmitted = true
                } else {
                    showError = true
                    searchSubmitted = false
                }
            }, label: {
                Text("Submit")
                    .animation(nil)
            })
            .buttonStyle(.bordered)
            .cornerRadius(cornerRadius)
            if (searchSubmitted && !loginSuccessful) {
                VStack {
                    if progressView {
                        ProgressView()
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        progressView = false
                    }
                }
                VStack {
                    if errorMessage {
                        Text("Login unsuccessful, please try again")
                            .padding()
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        errorMessage = true
                    }
                }
            }
            if showError {
                Text("You must enter both fields to search")
                    .foregroundColor(Color.red)
                
            } else {
                Text("")
            }
            Spacer()
        }
        .padding(.bottom, maxHeightOffset)
        .onAppear {
            divemeetsID = ""
            password = ""
        }
    }
}



private extension LoginSearchInputView {
    var hasReachedStart: Bool {
        self.focusedField == LoginField.allCases.first
    }
    
    var hasReachedEnd: Bool {
        self.focusedField == LoginField.allCases.last
    }
    
    func dismissKeyboard() {
        self.focusedField = nil
    }
    
    func next() {
        guard let currentInput = focusedField,
              let lastIndex = LoginField.allCases.last?.rawValue else { return }
        
        let index = min(currentInput.rawValue + 1, lastIndex)
        self.focusedField = LoginField(rawValue: index)
    }
    
    func previous() {
        guard let currentInput = focusedField,
              let firstIndex = LoginField.allCases.first?.rawValue else { return }
        
        let index = max(currentInput.rawValue - 1, firstIndex)
        self.focusedField = LoginField(rawValue: index)
    }
}
