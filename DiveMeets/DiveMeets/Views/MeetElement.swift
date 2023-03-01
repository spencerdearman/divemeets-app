//
//  MeetElement.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct MeetElement: View {
    var meet0: Meet

    var body: some View {
        HStack {
            Text(meet0.meetName)
        }
    }
}

struct LandmarkRow_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            MeetElement(meet0: meets[0])
            MeetElement(meet0: meets[1])
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
