//
//  CollapsingScrollView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 5/10/23.
//
//  https://www.youtube.com/watch?v=c6cYeLN9YoY
//

import SwiftUI

struct CollapsingScrollView: View {
    
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Album Songs")
                    .font(.system(size: 40))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer(minLength: 0)
            }
            .padding()
            .padding(.top, (UIApplication.shared.firstWindow?.safeAreaInsets.top))
            .background(Color.white.shadow(color: Color.black.opacity(0.2), radius: 5,
                                           x: 0, y: 5))
            .zIndex(0)
            
            GeometryReader { mainView in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 15) {
                        ForEach(1..<20) { i in
                            
                            GeometryReader { item in
                                
                                ZStack {
                                    Rectangle()
                                        .foregroundColor(.white)
                                    Text(String(i))
                                }
                                .background(Color.white.shadow(color: Color.black.opacity(0.12),
                                                               radius: 5, x: 0, y: 4))
                                .cornerRadius(15)
                                .scaleEffect(scaleValue(
                                    mainFrame: mainView.frame(in: .global).minY,
                                    minY: item.frame(in: .global).minY), anchor: .bottom)
                                .opacity(scaleValue(
                                    mainFrame: mainView.frame(in: .global).minY,
                                    minY: item.frame(in: .global).minY))
                            }
                            .frame(height: 100)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 25)
                }
                .zIndex(1)
            }
        }
        .background(Color.black.opacity(0.06).edgesIgnoringSafeArea(.all))
        .edgesIgnoringSafeArea(.top)
    }
    
    // Simple calculation for scaling effecat
    
    func scaleValue(mainFrame: CGFloat, minY: CGFloat) -> CGFloat {
        
        withAnimation(.easeOut) {
            let scale = (minY - 25) / mainFrame
            
            if scale > 1 {
                return 1
            } else {
                return scale
            }
        }
    }
}

struct CollapsingScrollView_Previews: PreviewProvider {
    static var previews: some View {
        CollapsingScrollView()
    }
}

// https://stackoverflow.com/questions/68387187/how-to-use-uiwindowscene-windows-on-ios-15
extension UIApplication {
    
    var firstWindow: UIWindow? {
        // Get connected scenes
        return UIApplication.shared.connectedScenes
        // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
        // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
        // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
        // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
}
