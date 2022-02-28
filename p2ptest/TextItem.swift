//
//  TextItem.swift
//  p2ptest
//
//  Created by Zhiyuan Huang on 2/23/22.
//

import Foundation

struct TextItem : Codable {
    
    var source:String
    var message:String
    var date:Date
    var uuid:UUID
    
    func saveItem() {
        DataManager.save(self, with: uuid.uuidString)
    }
    
    func deleteItem() {
        DataManager.delete(uuid.uuidString)
    }
    
}
