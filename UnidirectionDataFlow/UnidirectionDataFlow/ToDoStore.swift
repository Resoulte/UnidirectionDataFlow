//
//  ToDoStore.swift
//  UnidirectionDataFlow
//
//  Created by 师飞 on 2019/3/19.
//  Copyright © 2019年 师飞. All rights reserved.
//

import Foundation

let dummy = ["Buy thr milk", "Take my dog", "Rent a car"]

struct ToDoStore {
    static let shared = ToDoStore()
    func getToDoItems(completionHandler: (([String]) -> Void)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completionHandler?(dummy)
        }
    }
}
