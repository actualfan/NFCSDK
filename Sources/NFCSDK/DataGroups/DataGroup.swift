//
//  DataGroup.swift
//
//  Created by OCR Labs on 01/02/2021.
//

import Foundation

@available(iOS 13, macOS 10.15, *)
public class DataGroup {
    public var datagroupType : DataGroupId = .Unknown
    
    public private(set) var body : [UInt8] = []
    
    public private(set) var data : [UInt8] = []
    
    var pos = 0
    
    required init( _ data : [UInt8] ) throws {
        self.data = data
        
        pos = 1
        let _ = try getNextLength()
        self.body = [UInt8](data[pos...])
        
        try parse(data)
    }
    
    func parse( _ data:[UInt8] ) throws {
    }
    
    func getNextTag() throws -> Int {
        var tag = 0
        if binToHex(data[pos]) & 0x0F == 0x0F {
            tag = Int(binToHex(data[pos..<pos+2]))
            pos += 2
        } else {
            tag = Int(data[pos])
            pos += 1
        }
        return tag
    }
    
    func getNextLength() throws -> Int  {
        let end = pos+4 < data.count ? pos+4 : data.count
        let (len, lenOffset) = try asn1Length([UInt8](data[pos..<end]))
        pos += lenOffset
        return len
    }
    
    func getNextValue() throws -> [UInt8] {
        let length = try getNextLength()
        let value = [UInt8](data[pos ..< pos+length])
        pos += length
        return value
    }
    
    public func hash( _ hashAlgorythm: String ) -> [UInt8]  {
        var ret : [UInt8] = []
        if hashAlgorythm == "SHA1" {
            ret = calcSHA1Hash(self.data)
        } else if hashAlgorythm == "SHA224" {
            ret = calcSHA224Hash(self.data)
        } else if hashAlgorythm == "SHA256" {
            ret = calcSHA256Hash(self.data)
        } else if hashAlgorythm == "SHA384" {
            ret = calcSHA384Hash(self.data)
        } else if hashAlgorythm == "SHA512" {
            ret = calcSHA512Hash(self.data)
        }
        
        return ret
    }
    
}
