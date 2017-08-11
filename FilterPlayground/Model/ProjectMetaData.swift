//
//  ProjectMetaData.swift
//  FilterPlayground
//
//  Created by Leo Thomas on 01.08.17.
//  Copyright © 2017 Leo Thomas. All rights reserved.
//

import Foundation

struct ProjectMetaData: Codable {
    
    var attributes: [KernelAttribute]
    var type: KernelType
    var name: String
    
    init(attributes: [KernelAttribute], type: KernelType) {
        self.attributes = attributes
        self.type = type
        self.name = "untitled"
    }
    
    func initialSource() -> String {
        let parameter = initalArguments().map{ "\($0.type.rawValue) \($0.name)" }.joined(separator: ",")
        return "kernel \(type.returnType) \(name)(\(parameter)) {\n\n}"
    }
    
    func initalArguments() -> [KernelAttribute] {
        return type.requiredArguments.map{ KernelAttribute(name: "unamed", type: $0, value: $0.defaultValue) }
    }
}
