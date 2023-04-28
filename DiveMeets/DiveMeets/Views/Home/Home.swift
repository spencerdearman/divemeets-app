//
//  Home.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 4/25/23.
//

import SwiftUI


struct Home: View {
    
    var body: some View {
        Text("Home")
    }
}
//import SwiftUI
//
//struct Fruit: Identifiable {
//    let id = UUID()
//    let name: String
//    let description: String
//}
//
//struct Home: View {
//    let fruits = [
//        Fruit(name: "Apple", description: "A round fruit with red, green, or yellow skin and a white inside."),
//        Fruit(name: "Banana", description: "A long, curved fruit with a yellow skin and a soft, sweet inside."),
//        Fruit(name: "Orange", description: "A round fruit with a thick, orange skin and a juicy, sweet inside."),
//        Fruit(name: "Grapes", description: "Small, round fruit with a soft, juicy inside and a skin that can be red, purple, or green."),
//        Fruit(name: "Watermelon", description: "A large, oblong fruit with a green skin and a juicy, red inside."),
//    ]
//
//    @State private var selectedFruit: Fruit?
//
//    var body: some View {
//        List(fruits) { fruit in
//            Button(action: {
//                selectedFruit == fruit ? nil : fruit
//            }) {
//                Text(fruit.name)
//                    .font(.headline)
//            }
//            .buttonStyle(ExpandableButtonStyle(isSelected: selectedFruit == fruit))
//            .scaleEffect(selectedFruit == fruit ? 1.1 : 1.0)
//            .animation(.easeInOut(duration: 0.2))
//            .expanded(isSelected: selectedFruit == fruit) {
//                Text(fruit.description)
//                    .foregroundColor(.secondary)
//                Divider()
//                Button(action: {}) {
//                    Text("Buy Now")
//                }
//            }
//        }
//    }
//}
//
//struct ExpandableButtonStyle: ButtonStyle {
//    let isSelected: Bool
//
//    func makeBody(configuration: Self.Configuration) -> some View {
//        configuration.label
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding()
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(Color.secondary.opacity(0.2))
//            )
//    }
//}

