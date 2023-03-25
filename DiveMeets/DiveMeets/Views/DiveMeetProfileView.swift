import SwiftUI
import WebKit

struct DiveMeetSearchView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var profileURL: URL?

    var body: some View {
        VStack {
            HStack {
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button(action: searchForProfile) {
                    Text("Search")
                }
                .padding()
            }
            if let url = profileURL {
                Text("\(url.absoluteString)")
                    .padding()
            } else {
                Text("Enter a first name and last name to search for a DiveMeet profile")
                    .padding()
            }
        }
    }

    private func searchForProfile() {
        guard !firstName.isEmpty, !lastName.isEmpty else { return }
        let searchString = "\"\(firstName) \(lastName)\" divemeets.com"
        let escapedString = searchString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let searchURL = URL(string: "https://www.google.com/search?q=\(escapedString)")!
        print(searchURL)
        let task = URLSession.shared.dataTask(with: searchURL) { [self] data, response, error in
            guard let data = data, error == nil else {
                print("Error searching for profile: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let htmlString = String(data: data, encoding: .utf8),
               let range = htmlString.range(of: "<a href=\"/url?q="),
               let endRange = htmlString.range(of: "&amp;", range: range.upperBound..<htmlString.endIndex) {
                let resultURL = htmlString[range.upperBound..<endRange.lowerBound]
                    .replacingOccurrences(of: "%3F", with: "?")
                    .replacingOccurrences(of: "%3D", with: "=")
                self.profileURL = URL(string: String(resultURL))
            } else {
                print("No profile found for \(firstName) \(lastName)")
            }
        }

        task.resume()
    }
}

struct DiveMeetSearchView_Previews: PreviewProvider {
    static var previews: some View {
        DiveMeetSearchView()
    }
}

