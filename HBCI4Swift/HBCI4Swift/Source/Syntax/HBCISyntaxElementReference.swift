//
//  HBCISyntaxElementReference.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 22.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISyntaxElementReference {
    let name:String!
    let minnum:Int
    let maxnum:Int
    let elemDescr: HBCISyntaxElementDescription;
    
    init(element:XMLElement, description: HBCISyntaxElementDescription) throws {
        self.elemDescr = description;

        var num = element.valueForAttribute("minnum")
        if num == nil {
            // Optional when all children are optional. This includes DEs, which have no children.
            num = description.children.allSatisfy({ $0.minnum == 0 }) ? "0" : "1";
        }
        self.minnum = Int(num!) ?? 1
        num = element.valueForAttribute("maxnum")
        if num != nil {
            self.maxnum = Int(num!) ?? 1
        } else {
            self.maxnum = 1;
        }

        if let name =  element.valueForAttribute("name") {
            self.name = name;
        } else if let name = element.valueForAttribute("type") {
            self.name = name;
        } else {
            logInfo("Missing attribute 'name' in element \(element.description)");
            self.name = "<unknown>";
            throw HBCIError.syntaxFileError;
        }

    }
}
