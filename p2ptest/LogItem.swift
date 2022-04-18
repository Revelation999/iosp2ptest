//
//  LogItem.swift
//  p2ptest
//
//  Created by Zhiyuan Huang on 4/10/22.
//

import Foundation

struct LogItem : Codable {
    var round:Int
    var currentState:[String:Float32]
    var date:Date
    var uuid:UUID
    
    func saveItem() {
        DataManager.save(self, with: uuid.uuidString)
    }
    
    func deleteItem() {
        DataManager.delete(uuid.uuidString)
    }
    
}
