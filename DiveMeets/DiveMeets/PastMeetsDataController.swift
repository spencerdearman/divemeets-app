//
//  PastMeetsDataController.swift
//  PastMeets
//
//  Created by Logan Sherwin on 4/3/23.
//

import CoreData
import Foundation

class PastMeetsDataController: ObservableObject {
    let container = NSPersistentContainer(name: "PastMeets")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load PastMeets: \(error.localizedDescription)")
            }
        }
    }
    
    // Replaces all instances of %s with %@, the argument replacement for NSPredicate
    private static func replaceStrings(predicate: String) -> String {
        do {
            var result = predicate
            let pattern = "%s"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsrange = NSRange(predicate.startIndex..<predicate.endIndex,
                                  in: predicate)
            
            regex.enumerateMatches(in: predicate, range: nsrange) {
                (match, _, _) in
                guard let match = match else { return }
                
                for i in 0..<match.numberOfRanges {
                    let m = predicate[Range(match.range(at: i), in: predicate)!]
                    print(m)
                    result = result.replacingOccurrences(of: m, with: "%@")
                }
            }
            
            return result
        } catch {
            print("String replacement failed")
            return predicate
        }
    }
    
    // Replaces all instances of %d with that Int, which is the format for NSPredicate
    private static func replaceInts(predicate: String, args: [Int]) -> String {
        do {
            var result = predicate
            let pattern = "%d"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsrange = NSRange(predicate.startIndex..<predicate.endIndex,
                                  in: predicate)
            var argsIdx = 0
            let numberOfMatches = regex.numberOfMatches(in: result, range: nsrange)
            assert(numberOfMatches == args.count)
            
            regex.enumerateMatches(in: predicate, range: nsrange) {
                (match, _, _) in
                guard let match = match else { return }
                
                for i in 0..<match.numberOfRanges {
                    let m = predicate[Range(match.range(at: i), in: predicate)!]
                    result = result.replacing(m, with: String(args[argsIdx]), maxReplacements: 1)
                    argsIdx += 1
                }
            }
            
            return result
        } catch {
            print("Int replacement failed")
            return predicate
        }
    }
    
    // Provide predicate string and arguments to provide to generate an NSPredicate
    // for CoreData querying;
    // Use %s to sub string, %d to sub int, and this will generate the appropraite
    // NSPredicate string formatting
    // Ex: PastMeetsDataController.createNSPredicate(predicate: "name beginswith %s AND year > %d", "Phoenix", 2020)
    //     --> This will produce an NSPredicate to use inside a @FetchRequest wrapper to get results from CoreData
    //           where the name starts with Phoenix and whose year is after 2020
    static func createNSPredicate(predicate: String, args: Any...) -> NSPredicate {
        var result = replaceStrings(predicate: predicate)
        var otherArgs: [String] = []
        var intArgs: [Int] = []
        
        for arg in args {
            if arg is Int {
                intArgs.append(arg as! Int)
            } else if arg is String {
                otherArgs.append(arg as! String)
            }
        }
        
        result = replaceInts(predicate: result, args: intArgs)
        
        return NSPredicate(format: result, otherArgs)
    }
}
