//
//  HBCICamtParser_052_001_02.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 02.07.20.
//  Copyright © 2020 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCICamtParser_052_001_02 : HBCISepaParser, HBCICamtParser {
    
    func parse(_ account:HBCIAccount, data:Data, isPreliminary:Bool) ->[HBCIStatement]? {
        
        logDebug(String(data: data, encoding: String.Encoding.utf8) ?? "<binary data>")
        
        do {
            let document = try XMLDocument(data: data, options: XMLNode.Options(rawValue: XMLNode.Options.RawValue(Int(XMLDocument.Options.documentTidyXML.rawValue))))
            if let root = document.rootElement() {
                var result = [HBCIStatement]();
                
                // Group Header
                // do we need something from Group Header?

                let reports = root.elementsForPath("BkToCstmrAcctRpt.Rpt");
                for report in reports {
                    let statement = HBCIStatement();
                    
                    for balanceElement in report.elementsForPath("Bal") {
                        if let balance = HBCIAccountBalance(element: balanceElement) {
                            switch balance.type {
                            case AccountBalanceType.PreviouslyClosedBooked: statement.startBalance = balance; break;
                            case AccountBalanceType.ClosingAvailable: statement.valutaBalance = balance; break;
                            case AccountBalanceType.ForwardAvailable: statement.futureValutaBalance = balance; break;
                            default: statement.endBalance = balance; break;
                            }
                        }
                    }
                    transferAccountData(account, statement: statement);
                    statement.statementRef = report.stringValueForPath("Id");
                    statement.statementNumber = report.stringValueForPath("ElctrncSeqNb")
                    statement.localIBAN = report.stringValueForPath("Acct.Id.IBAN");
                    statement.localBIC = report.stringValueForPath("Acct.Svcr.FinInstnId.BICFI");
                    
                    statement.isPreliminary = isPreliminary;
                    
                    for entry in report.elements(forName: "Ntry") {
                        let item = HBCIStatementItem();
                        
                        guard let status = entry.stringValueForPath("Sts") else {
                            return nil;
                        }
                        
                        guard let amtElem = entry.elements(forName: "Amt").first else {
                            return nil;
                        }
                        guard let amount = HBCIValue(element: amtElem) else {
                            return nil;
                        }
                        guard let dc = entry.stringValueForPath("CdtDbtInd") else {
                            return nil;
                        }
                        if dc == "DBIT" {
                            item.value = NSDecimalNumber.zero.subtracting(amount.value);
                        } else {
                            item.value = amount.value;
                        }
                        
                        if status == "INFO" {
                            continue;
                        }
                        
                        if isPreliminary == false && status != "BOOK" {
                            continue;
                        }
                        
                        item.currency = amount.currency;
                        if let dateString = entry.stringValueForPath("BookgDt.Dt") {
                            item.date = stringToDate(dateString);
                        }
                        
                        if item.date == nil {
                            if let dateString = entry.stringValueForPath("BookgDt.DtTm") {
                                item.date = timestampToDate(dateString);
                            }
                        }
                        
                        if let dateString = entry.stringValueForPath("ValDt.Dt") {
                            item.valutaDate = stringToDate(dateString);
                        }
                        if item.valutaDate == nil {
                            if let dateString = entry.stringValueForPath("ValDt.DtTm") {
                                item.valutaDate = timestampToDate(dateString);
                            }
                        }
                        
                        if item.date == nil && item.valutaDate == nil {
                            logInfo("Skipping entry without date or valuta date:")
                            logInfo(entry.description)
                            continue
                        }
                        
                        // get whatever date we have...
                        if item.valutaDate == nil {
                            item.valutaDate = item.date;
                        }
                        
                        if item.date == nil {
                            item.date = item.valutaDate;
                        }
                        
                        item.bankReference = entry.stringValueForPath("AcctSvcrRef");
                        item.transactionText = entry.stringValueForPath("AddtlNtryInf");
                        guard let detElem = entry.elementsForPath("NtryDtls.TxDtls").first else {
                            return nil;
                        }
                        if dc == "DBIT" {
                            item.remoteIBAN = detElem.stringValueForPath("RltdPties.CdtrAcct.Id.IBAN");
                            item.remoteBIC = detElem.stringValueForPath("RltdAgts.CdtrAgt.FinInstnId.BICFI");
                            item.remoteName = detElem.stringValueForPath("RltdPties.Cdtr.Nm");
                        } else {
                            item.remoteIBAN = detElem.stringValueForPath("RltdPties.DbtrAcct.Id.IBAN");
                            item.remoteBIC = detElem.stringValueForPath("RltdAgts.DbtrAgt.FinInstnId.BICFI");
                            item.remoteName = detElem.stringValueForPath("RltdPties.Dbtr.Nm");
                        }
                        var purpose = "";
                        for purpElem in detElem.elementsForPath("RmtInf.Ustrd") {
                            purpose = purpose + (purpElem.stringValue ?? "");
                        }
                        if purpose.count == 0 {
                            if let transactionText = item.transactionText {
                                if transactionText.count > 0 {
                                    let parts = transactionText.split(separator: ";");
                                    item.transactionText = String(parts.first ?? "");
                                    for part in parts {
                                        purpose += part;
                                    }
                                }
                            }
                        }
                        item.purpose = purpose;
                        
                        item.endToEndId = detElem.stringValueForPath("Refs.EndToEndId");
                        item.customerReference = detElem.stringValueForPath("Refs.InstrId");
                        item.mandateId = detElem.stringValueForPath("Refs.MndtId");
                        item.debitorId = detElem.stringValueForPath("RltdPties.Dbtr.Nm");
                        item.creditorId = detElem.stringValueForPath("RltdPties.Cdtr.Nm");
                        item.ultimateDebitorId = detElem.stringValueForPath("RltdPties.UltmtDbtr.Nm");
                        item.ultimateCreditorId = detElem.stringValueForPath("RltdPties.UltmtCdtr.Nm");
                        item.purposeCode = detElem.stringValueForPath("Purp.Cd");
                        
                        item.isSEPA = true;
                        item.isCancellation = false;
                        statement.items.append(item);
                    }
                    
                    result.append(statement);
                }
                return result;
            }
        }
        catch let err as NSError {
            logInfo(err.description);
            return nil;
        }
        return nil;
    }
}
