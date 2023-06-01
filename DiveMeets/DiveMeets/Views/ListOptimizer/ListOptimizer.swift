//
//  ListOptimizer.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/31/23.
//

import SwiftUI

struct ListOptimizer: View {
    
    func generateJSONString(from dictionary: [String: Any]) -> String? {
        do {
            var dic = dictionary
            for (key, value) in dic {
                if let nestedTuple = value as? (String, [Float: Float]) {
                    let nestedDic: [String: Any] = [
                        "name": nestedTuple.0,
                        "values": nestedTuple.1
                    ]
                    dic[key] = nestedDic
                }
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    // Usage example
    let dictionary: [String: Any] =
    ["101A" : ("Forward Dive Straight", [1: 1.4, 3: 1.6, 5: 1.4, 7.5: 1.6, 10: 1.6]),
     "101B": ("Forward Dive Pike", [1: 1.3, 3: 1.5, 5: 1.3, 7.5: 1.5, 10: 1.5]),
     "101C": ("Forward Dive Tuck", [1: 1.2, 3: 1.4, 5: 1.2, 7.5: 1.4, 10: 1.4]),
     "102A": ("Forward Somersault Straight", [1: 1.6, 3: 1.7, 5: 1.6, 7.5: 1.7, 10: 1.8]),
     "102B": ("Forward Somersault Pike", [1: 1.5, 3: 1.6]),
     "102C": ("Forward Somersault Tuck", [1: 1.4]),
     "103A": ("Forward 1 ½ Somersault Straight", [1: 2.0]),
     "103B": ("Forward 1 ½ Somersault Pike", [1: 1.7]),
     "103C": ("Forward 1 ½ Somersault Tuck", [1: 1.6]),
     "104A": ("Forward Double Somersault Straight", [1: 2.6]),
     "104B": ("Forward Double Somersault Pike", [1: 2.3]),
     "104C": ("Forward Double Somersault Tuck", [1: 2.2]),
     "105A": ("Forward 2 ½ Somersault Straight", [3: 2.8]),
     "105B": ("Forward 2 ½ Somersault Pike", [1: 2.6]),
     "105C": ("Forward 2 ½ Somersault Tuck", [1: 2.4]),
     "106B": ("Forward Triple Somersault Pike", [1: 3.2]),
     "106C": ("Forward Triple Somersault Tuck", [1: 2.9]),
     "107B": ("Forward 3 ½ Somersault Pike", [1: 3.3]),
     "107C": ("Forward 3 ½ Somersault Tuck", [1: 3.0]),
     "112B": ("Forward Flying Somersault Pike", [1: 1.7]),
     "112C": ("Forward Flying Somersault Tuck", [1: 1.6]),
     "113B": ("Forward Flying 1 ½ Somersault Pike", [1: 1.9]),
     "113C": ("Forward Flying 1 ½ Somersault Tuck", [1: 1.8]),
     "114C": ("Forward Flying Double Somersault Tuck", [7: 2.2, 10: 2.3]),
     "115B": ("Forward Flying 2 ½ Somersault Pike", [3: 2.7]),
     "115C": ("Forward Flying 2 ½ Somersault Tuck", [3: 2.5]),
     "201A": ("Back Dive Straight", 1.7),
     "201B": ("Back Dive Pike", 1.6),
     "201C": ("Back Dive Tuck", 1.5),
     "202A": ("Back Somersault Straight", 1.7),
     "202B": ("Back Somersault Pike", 1.6),
     "202C": ("Back Somersault Tuck", 1.5),
     "203A": ("Back 1 ½ Somersault Straight", 2.5),
     "203B": ("Back 1 ½ Somersault Pike", 2.3),
     "203C": ("Back 1 ½ Somersault Tuck", 2.0),
     "204B": ("Back Double Somersault Pike", 2.5),
     "204C": ("Back Double Somersault Tuck", 2.2),
     "205B": ("Back 2 ½ Somersault Pike", 3.2),
     "205C": ("Back 2 ½ Somersault Tuck", 3.0),
     "206B": ("Back Triple Somersault Pike", 3.2),
     "206C": ("Back Triple Somersault Tuck", 2.9),
     "212B": ("Back Flying Somersault Pike", 1.7),
     "212C": ("Back Flying Somersault Tuck", 1.6),
     "301A": ("Reverse Dive Straight", 1.8),
     "301B": ("Reverse Dive Pike", 1.7),
     "301C": ("Reverse Dive Tuck", 1.6),
     "302A": ("Reverse Somersault Straight", 1.8),
     "302B": ("Reverse Somersault Pike", 1.7),
     "302C": ("Reverse Somersault Tuck", 1.6),
     "303A": ("Reverse 1 ½ Somersault Straight", 2.7),
     "303B": ("Reverse 1 ½ Somersault Pike", 2.4),
     "303C": ("Reverse 1 ½ Somersault Tuck", 2.1),
     "304A": ("Reverse Double Somersault Straight", 2.9),
     "304B": ("Reverse Double Somersault Pike", 2.6),
     "304C": ("Reverse Double Somersault Tuck", 2.3),
     "305B": ("Reverse 2 ½ Somersault Pike", 3.2),
     "305C": ("Reverse 2 ½ Somersault Tuck", 3.0),
     "306B": ("Reverse Triple Somersault Pike", 3.3),
     "306C": ("Reverse Triple Somersault Tuck", 3.0),
     "312B": ("Reverse Flying Somersault Pike", 1.8),
     "312C": ("Reverse Flying Somersault Tuck", 1.7),
     "313B": ("Reverse Flying 1 ½ Somersault Pike", 2.6),
     "313C": ("Reverse Flying 1 ½ Somersault Tuck", 2.3),
     "401A": ("Inward Dive Straight", 1.8),
     "401B": ("Inward Dive Pike", 1.5),
     "401C": ("Inward Dive Tuck", 1.4),
     "402A": ("Inward Somersault Straight", 2.0),
     "402B": ("Inward Somersault Pike", 1.7),
     "402C": ("Inward Somersault Tuck", 1.6),
     "403B": ("Inward 1 ½ Somersault Pike", 2.4),
     "403C": ("Inward 1 ½ Somersault Tuck", 2.2),
     "404B": ("Inward Double Somersault Pike", 3.0),
     "404C": ("Inward Double Somersault Tuck", 2.8),
     "405B": ("Inward 2 ½ Somersault Pike", 3.4),
     "405C": ("Inward 2 ½ Somersault Tuck", 3.1),
     "412B": ("Inward Flying Somersault Pike", 2.1),
     "412C": ("Inward Flying Somersault Tuck", 2.0),
     "413B": ("Inward Flying 1 ½ Somersault Pike", 2.9),
     "413C": ("Inward Flying 1 ½ Somersault Tuck", 2.7),
     "5111A": ("Forward Dive ½ Twist Straight", 1.8),
     "5111B": ("Forward Dive ½ Twist Pike", 1.7),
     "5111C": ("Forward Dive ½ Twist Tuck", 1.6),
     "5112A": ("Forward Dive 1 Twist Straight", 2.0),
     "5112B": ("Forward Dive 1 Twist Pike", 1.9),
     "5121D": ("Forward Somersault ½ Twist Free", 1.7),
     "5122D": ("Forward Somersault 1 Twist Free", 1.9),
     "5124D": ("Forward Somersault 2 Twists Free", 2.3),
     "5126D": ("Forward Somersault 3 Twists Free", 2.7),
     "5131D": ("Forward 1 ½ Somersault ½ Twist Free", 2.0),
     "5132D": ("Forward 1 ½ Somersault 1 Twist Free", 2.2),
     "5134D": ("Forward 1 ½ Somersault 2 Twists Free", 2.6),
     "5136D": ("Forward 1 ½ Somersault 3 Twists Free", 3.0),
     "5138D": ("Forward 1 ½ Somersault 4 Twists Free", 3.4),
     "5151B": ("Forward 2 ½ Somersault ½ Twist Pike", 3.0),
     "5151C": ("Forward 2 ½ Somersault ½ Twist Tuck", 2.8),
     "5152B": ("Forward 2 ½ Somersault 1 Twist Pike", 3.2),
     "5152C": ("Forward 2 ½ Somersault 1 Twist Tuck", 3.0),
     "5154B": ("Forward 2 ½ Somersault 2 Twists Pike", 3.6),
     "5154C": ("Forward 2 ½ Somersault 2 Twists Tuck", 3.4),
     "5211A": ("Back Dive ½ Twist Straight", 1.8),
     "5211B": ("Back Dive ½ Twist Pike", 1.7),
     "5211C": ("Back Dive ½ Twist Tuck", 1.6),
     "5212A": ("Back Dive 1 Twist Straight", 2.0),
     "5221D": ("Back Somersault ½ Twist Free", 1.7),
     "5222D": ("Back Somersault 1 Twist Free", 1.9),
     "5223D": ("Back Somersault 1 ½ Twist Free", 2.3),
     "5225D": ("Back Somersault 2 ½ Twist Free", 2.7),
     "5227D": ("Back Somersault 3 ½ Twist Free", 3.1),
     "5231D": ("Back 1 ½ Somersault ½ Twist Free", 2.1),
     "5233D": ("Back 1 ½ Somersault 1 ½ Twist Free", 2.5),
     "5235D": ("Back 1 ½ Somersault 2 ½ Twist Free", 2.9),
     "5251B": ("Back 2 ½ Somersault ½ Twist Pike", 2.9),
     "5251C": ("Back 2 ½ Somersault ½ Twist Tuck", 2.7),
     "5311A": ("Reverse Dive ½ Twist Straight", 1.9),
     "5311B": ("Reverse Dive ½ Twist Pike", 1.8),
     "5311C": ("Reverse Dive ½ Twist Tuck", 1.7),
     "5312A": ("Reverse Dive 1 Twist Straight", 2.1),
     "5321D": ("Reverse Somersault ½ Twist Free", 1.8),
     "5322D": ("Reverse Somersault 1 Twist Free", 2.0),
     "5323D": ("Reverse Somersault 1 ½ Twist Free", 2.4),
     "5325D": ("Reverse Somersault 2 ½ Twist Free", 2.8),
     "5331D": ("Reverse 1 ½ Somersault ½ Twist Free", 2.2),
     "5333D": ("Reverse 1 ½ Somersault 1 ½ Twist Free", 2.6),
     "5335D": ("Reverse 1 ½ Somersault 2 ½ Twist Free", 3.0),
     "5337D": ("Reverse 1 ½ Somersault 3 ½ Twist Free", 3.4),
     "5351B": ("Rev. 2 ½ Somersault ½ Twist Pike", 2.9),
     "5351C": ("Rev. 2 ½ Somersault ½ Twist Tuck", 2.7),
     "5353C": ("Rev. 2 ½ Somersault 1 ½ Twist Tuck", 3.5),
     "5411A": ("Inward Dive ½ Twist Straight", 2.0),
     "5411B": ("Inward Dive ½ Twist Pike", 1.7),
     "5411C": ("Inward Dive ½ Twist Tuck", 1.6),
     "5412A": ("Inward Dive 1 Twist Straight", 2.2),
     "5412B": ("Inward Dive 1 Twist Pike", 1.9),
     "5412C": ("Inward Dive 1 Twist Tuck", 1.8),
     "5421D": ("Inward Somersault ½ Twist Free", 1.9),
     "5422D": ("Inward Somersault 1 Twist Free", 2.1),
     "5432D": ("Inward 1 ½ Somersault 1 Twist Free", 2.7),
     "5434D": ("Inward 1 ½ Somersault 2 Twist Free", 3.1)
    ]
    
    var body: some View {
        ZStack{}
            .onAppear{
                if let jsonString = generateJSONString(from: dictionary) {
                    print(jsonString)
                }
            }
    }
}
