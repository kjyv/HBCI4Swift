//
//  HBCISepaParser.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 22.05.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISepaParser {
    //let format:HBCISepaFormat;

    let numberFormatter = NumberFormatter();
    let dateTimeFormatter = ISO8601DateFormatter();

    init() {
        //self.format = format;
        initFormatters();
    }
    
    fileprivate func initFormatters() {
        numberFormatter.decimalSeparator = ".";
        numberFormatter.alwaysShowsDecimalSeparator = true;
        numberFormatter.minimumFractionDigits = 2;
        numberFormatter.maximumFractionDigits = 2;
        numberFormatter.generatesDecimalNumbers = true;
        
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
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd";
        let str = String(s.prefix(10));
        if let date = formatter.date(from: str) {
            return date;
        } else {
            logInfo("Sepa document parser: not able to convert \(str) to a date");
            return nil;
        }
    }
    
    // Fallback for reports that do not name the account.
    func transferAccountData(_ account:HBCIAccount, statement:HBCIStatement) {
        statement.localAccountNumber = account.number;
        statement.localIBAN = account.iban;
        statement.localBankCode = account.bankCode;
        statement.localBIC = account.bic;
    }

    func checkTransferData(_ iban:String?, bic:String?, name:String?, value:NSDecimalNumber?, currency:String?) ->Bool {
        if iban == nil {
            logInfo("Sepa document parser: IBAN is missing");
            return false;
        }
        if bic == nil {
            logInfo("Sepa document parser: BIC is missing");
            return false;
        }
        if name == nil {
            logInfo("Sepa document parser: Creditor name is missing");
            return false;
        }
        if value == nil {
            logInfo("Sepa document parser: value is missing");
            return false;
        }
        if currency == nil {
            logInfo("Sepa document parser: currency is missing");
            return false;
        }
        return true;
    }

}
