//
//  Cursos.swift
//  iOS1FirebaseIntegration
//
//  Created by Domiciano Rincón on 11/06/20.
//  Copyright © 2020 Domiciano Rincón. All rights reserved.
//

import Foundation


class ResultSet{
    
    private var data:[[String]]
    private var pointer = -1;
    
    init(data:[[String]]){
        self.data = data
    }
    
    func next() -> Bool {
        pointer += 1
        if pointer >= data.count{
            return false
        }else{
            return true
        }
    }
    
    func getStringAt(column:Int) -> String {
        return data[pointer][column]
    }
    
    func getIntAt(column:Int) -> Int {
        let value = Int(data[pointer][column])
        guard let integer = value else{
            print("Is not a number")
            return -1
        }
        return integer
    }
    
}
