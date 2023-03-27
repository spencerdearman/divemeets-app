//
//  ProfileMeetCache.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/27/23.
//

import Foundation

class ProfileMeetCache: CustomCache {
    static let cacheName = "profileMeets"
    
    static var cache: Cache<String, [Array<String>]> = {
        do {
            return try Cache<String, [Array<String>]>.loadFromDisk(withName: cacheName)
        } catch {
            return Cache<String, [Array<String>]>()
        }
    }()
    
    static func saveToDisk() {
        do {
            try cache.saveToDisk(withName: ProfileMeetCache.cacheName)
            print("Save succeeded")
        } catch {
            print("Failed to save profileMeets cache to disk")
        }
    }
    
    static func loadFromDisk() {
        do {
            ProfileMeetCache.cache = try Cache<String, [Array<String>]>.loadFromDisk(withName: cacheName)
            print("Load succeeded")
        } catch {
            ProfileMeetCache.cache = Cache<String, [Array<String>]>()
            print("Load failed")
        }
    }
    
    static func clearCacheFromDisk() {
        let fileManager: FileManager = .default
        let name = ProfileMeetCache.cacheName
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        
        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        if fileManager.fileExists(atPath: fileURL.absoluteString) {
            do {
                try fileManager.removeItem(atPath: fileURL.absoluteString)
            } catch {
                print("File removal failed")
            }
        } else {
            print("Cache file does not exist")
        }
    }
}

extension ProfileMeetCache {
    static subscript(key: String) -> [Array<String>]? {
        get { return ProfileMeetCache.cache.value(forKey: key) }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                ProfileMeetCache.cache.removeValue(forKey: key)
                return
            }
            
            ProfileMeetCache.cache.insert(value, forKey: key)
        }
    }
}
