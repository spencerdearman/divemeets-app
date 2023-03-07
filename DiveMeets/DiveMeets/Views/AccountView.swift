//
//  AccountView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/6/23.
//

import SwiftUI

private let users: [String: String] = ["Lsherwin": "Lsherwin"]

private func attemptLogin(username: String, password: String) -> Bool {
    if users[username] != nil && password == users[username] {
        return true
    }
    return false
}

struct AccountView: View {
    @State private var signedIn: Bool = false
    @State private var loginFailed: Bool = false
    @State private var hideTabBar: Bool = false
    
    var body: some View {
        if signedIn {
            ProfileView(hideTabBar: $hideTabBar)
        } else {
            LoginView(signedIn: $signedIn, loginFailed: $loginFailed)
        }
    }
}

struct LoginView: View {
    @Binding var signedIn: Bool
    @Binding var loginFailed: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    private let cornerRadius: CGFloat = 30
    
    var body: some View {
        VStack {
            Text("Login")
                .font(.title)
                .bold()
                .padding(.bottom)
            VStack {
                HStack {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                }
                .padding([.leading, .trailing], 50)
                HStack {
                    TextField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding([.leading, .trailing], 50)
                Button(action: {
                    if attemptLogin(username: username, password: password) {
                        signedIn = true
                    } else {
                        loginFailed = true
                    }
                }, label: {
                    Text("Log in")
                })
                .buttonStyle(.bordered)
                .cornerRadius(cornerRadius)
                .padding(.vertical)
                if loginFailed {
                    Text("Login failed, please try again")
                        .foregroundColor(Color.red)
                } else {
                    Text(" ")
                }
            }
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            AccountView().preferredColorScheme($0)
        }
    }
}
