//
//  MeetList.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct MeetList: View {
    var body: some View {
        NavigationView {
            List(meets) { meet in
                NavigationLink {
                    MeetPage(meetInstance: meet)
                } label: {
                    MeetElement(meet0: meet)
                }
            }
            .navigationTitle("Meets")
        }
    }
}

struct MeetList_Previews: PreviewProvider {
    static var previews: some View {
        MeetList()
    }
}
