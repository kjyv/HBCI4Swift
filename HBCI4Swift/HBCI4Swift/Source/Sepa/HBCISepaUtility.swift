//
//  HBCISepaUtility.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 03.07.20.
//  Copyright © 2020 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaUtility {
    let numberFormatter = NumberFormatter();
    let dateFormatter = DateFormatter();
    let dateTimeFormatter = ISO8601DateFormatter();

    init() {
        initFormatters();
    }
    
    fileprivate func initFormatters() {
        numberFormatter.decimalSeparator = ".";
        numberFormatter.alwaysShowsDecimalSeparator = true;
        numberFormatter.minimumFractionDigits = 2;
        numberFormatter.maximumFractionDigits = 2;
        numberFormatter.generatesDecimalNumbers = true;

        dateFormatter.dateFormat = "yyyy-MM-dd";
        
        dateTimeFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds];
    }

    func stringToNumber(_ s:String) ->NSDecimalNumber? {
        if let number = numberFormatter.number(from: s) as? NSDecimalNumber {
            return number;
        } else {
            logInfo("Sepa document parser: not able to convert \(s) to a value");
            return nil;
        }
    }
    
    func timestampToDate(_ s:String) ->Date? {
        return dateTimeFormatter.date(from: s);
    }
    
    func stringToDate(_ s:String) ->Date? {
        let str = String(s.prefix(10));
        if let date = dateFormatter.date(from: str) {
            return date;
        } else {
            logInfo("Sepa document parser: not able to convert \(str) to a date");
            return nil;
        }
    }

}
