//
//  MeetList.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct MeetList: View {
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 15
    private let rowSpacing: CGFloat = 3
    private let rowColor: Color = Color.white
    private let textColor: Color = Color.black
    private let fontSize: CGFloat = 20
    private let grayValue: CGFloat = 0.95
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: grayValue, green: grayValue, blue: grayValue)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: rowSpacing) {
                        ForEach(meets) { meet in
                            NavigationLink(destination: MeetPage(meetInstance: meet)) {
                                GeometryReader { geometry in
                                    HStack {
                                        MeetElement(meet0: meet)
                                            .foregroundColor(textColor)
                                            .font(.system(size: fontSize))
                                            .padding()
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color.gray)
                                            .padding()
                                    }
                                    .frame(width: frameWidth, height: frameHeight)
                                    .background(rowColor)
                                    .cornerRadius(cornerRadius)
                                }
                                .frame(width: frameWidth, height: frameHeight)
                            }
                        }
                    }
                }
                .navigationTitle("Meets")
            }
        }
    }
}

struct MeetList_Previews: PreviewProvider {
    static var previews: some View {
        MeetList()
    }
}
