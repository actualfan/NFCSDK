//
//  Utils.swift
//  NFCSDK
//
//  Created by OCR Labs on 09/06/2019.
//  Copyright © 2019 OCR Labs. All rights reserved.
//

import Foundation
import CommonCrypto
import CryptoTokenKit

#if canImport(CryptoKit)
    import CryptoKit
#endif

private extension UInt8 {
    var hexString: String {
        let string = String(self, radix: 16)
        return (self < 16 ? "0" + string : string)
    }
}


extension FileManager {
    static var documentDir : URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

extension StringProtocol {
    subscript(bounds: CountableClosedRange<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(start, offsetBy: bounds.count)
        return self[start..<end]
    }
    
    subscript(bounds: CountableRange<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(start, offsetBy: bounds.count)
        return self[start..<end]
    }
    
    func index(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }

}


public func binToHexRep( _ val : [UInt8], asArray : Bool = false ) -> String {
    var string = asArray ? "[" : ""
    for x in val {
        if asArray {
            string += String(format:"0x%02x, ", x )

        } else {
            string += String(format:"%02x", x )
        }
    }
    string += asArray ? "]" : ""
    return asArray ? string : string.uppercased()
}

public func binToHexRep( _ val : UInt8 ) -> String {
    let string = String(format:"%02x", val ).uppercased()
    return string
}

public func binToHex( _ val: UInt8 ) -> Int {
    let hexRep = String(format:"%02X", val)
    return Int(hexRep, radix:16)!
}

public func binToHex( _ val: [UInt8] ) -> UInt64 {
    let hexVal = UInt64(binToHexRep(val), radix:16)!
    return hexVal
}

public func binToHex( _ val: ArraySlice<UInt8> ) -> UInt64 {
    return binToHex( [UInt8](val) )
}


public func hexToBin( _ val : UInt64 ) -> [UInt8] {
    let hexRep = String(format:"%lx", val)
    return hexRepToBin( hexRep)
}

public func binToInt( _ val: ArraySlice<UInt8> ) -> Int {
    let hexVal = binToInt( [UInt8](val) )
    return hexVal
}

public func binToInt( _ val: [UInt8] ) -> Int {
    let hexVal = Int(binToHexRep(val), radix:16)!
    return hexVal
}

public func intToBin(_ data : Int, pad : Int = 2) -> [UInt8] {
    if pad == 2 {
        let hex = String(format:"%02x", data)
        return hexRepToBin(hex)
    } else {
        let hex = String(format:"%04x", data)
        return hexRepToBin(hex)

    }
}

public func hexRepToBin(_ val : String) -> [UInt8] {
    var output : [UInt8] = []
    var x = 0
    while x < val.count {
        if x+2 <= val.count {
            output.append( UInt8(val[x ..< x + 2], radix:16)! )
        } else {
            output.append( UInt8(val[x ..< x+1], radix:16)! )

        }
        x += 2
    }
    return output
}

public func xor(_ kifd : [UInt8], _ response_kicc : [UInt8] ) -> [UInt8] {
    var kseed = [UInt8]()
    for i in 0 ..< kifd.count {
        kseed.append( kifd[i] ^ response_kicc[i] )
    }
    return kseed
}

public func generateRandomUInt8Array( _ size: Int ) -> [UInt8] {
    
    var ret : [UInt8] = []
    for _ in 0 ..< size {
        ret.append( UInt8(arc4random_uniform(UInt32(UInt8.max) + 1)) )
    }
    return ret
}

public func pad(_ toPad : [UInt8], blockSize : Int) -> [UInt8] {
    
    var ret = toPad + [0x80]
    while ret.count % blockSize != 0 {
        ret.append(0x00)
    }
    return ret
}

public func unpad( _ tounpad : [UInt8]) -> [UInt8] {
    var i = tounpad.count-1
    while tounpad[i] == 0x00 {
        i -= 1
    }
    
    if tounpad[i] == 0x80 {
        return [UInt8](tounpad[0..<i])
    } else {
        return tounpad
    }
}

@available(iOS 13, macOS 10.15, *)
public func mac(algoName: SecureMessagingSupportedAlgorithms, key : [UInt8], msg : [UInt8]) -> [UInt8] {
    if algoName == .DES {
        return desMAC(key: key, msg: msg)
    } else {
        return aesMAC(key: key, msg: msg)
    }
}

@available(iOS 13, macOS 10.15, *)
public func desMAC(key : [UInt8], msg : [UInt8]) -> [UInt8]{
    
    let size = msg.count / 8
    var y : [UInt8] = [0,0,0,0,0,0,0,0]
    
    Log.verbose("Calc mac" )
    for i in 0 ..< size {
        let tmp = [UInt8](msg[i*8 ..< i*8+8])
        Log.verbose("x\(i): \(binToHexRep(tmp))" )
        y = DESEncrypt(key: [UInt8](key[0..<8]), message: tmp, iv: y)
        Log.verbose("y\(i): \(binToHexRep(y))" )
    }
    
    Log.verbose("y: \(binToHexRep(y))" )
    Log.verbose("bkey: \(binToHexRep([UInt8](key[8..<16])))" )
    Log.verbose("akey: \(binToHexRep([UInt8](key[0..<8])))" )
    let iv : [UInt8] = [0,0,0,0,0,0,0,0]
    let b = DESDecrypt(key: [UInt8](key[8..<16]), message: y, iv: iv, options:UInt32(kCCOptionECBMode))
    Log.verbose( "b: \(binToHexRep(b))" )
    let a = DESEncrypt(key: [UInt8](key[0..<8]), message: b, iv: iv, options:UInt32(kCCOptionECBMode))
    Log.verbose( "a: \(binToHexRep(a))" )
    
    return a
}

@available(iOS 13, macOS 10.15, *)
public func aesMAC( key: [UInt8], msg : [UInt8] ) -> [UInt8] {
    let mac = OpenSSLUtils.generateAESCMAC( key: key, message:msg )
    return mac
}

@available(iOS 13, macOS 10.15, *)
public func wrapDO( b : UInt8, arr : [UInt8] ) -> [UInt8] {
    let tag = TKBERTLVRecord(tag: TKTLVTag(b), value: Data(arr))
    let result = [UInt8](tag.data)
    return result;
}

@available(iOS 13, macOS 10.15, *)
public func unwrapDO( tag : UInt8, wrappedData : [UInt8]) throws -> [UInt8] {
    guard let rec = TKBERTLVRecord(from: Data(wrappedData)),
          rec.tag == tag else {
        throw NFCSDKError.InvalidASN1Value
    }
    return [UInt8](rec.value);
}


public func intToBytes( val: Int, removePadding:Bool) -> [UInt8] {
    if val == 0 {
        return [0]
    }
    var data = withUnsafeBytes(of: val.bigEndian, Array.init)

    if removePadding {
        for i in 0 ..< data.count {
            if data[i] != 0 {
                data = [UInt8](data[i...])
                break
            }
        }
    }
    return data
}

@available(iOS 13, macOS 10.15, *)
public func oidToBytes(oid : String, replaceTag : Bool) -> [UInt8] {
    var encOID = OpenSSLUtils.asn1EncodeOID(oid: oid)
    
    if replaceTag {
        encOID[0] = 0x80
    }
    return encOID
}



@available(iOS 13, macOS 10.15, *)
public func asn1Length( _ data: ArraySlice<UInt8> ) throws -> (Int, Int) {
    return try asn1Length( Array(data) )
}

@available(iOS 13, macOS 10.15, *)
public func asn1Length(_ data : [UInt8]) throws -> (Int, Int)  {
    if data[0] < 0x80 {
        return (Int(binToHex(data[0])), 1)
    }
    if data[0] == 0x81 {
        return (Int(binToHex(data[1])), 2)
    }
    if data[0] == 0x82 {
        let val = binToHex([UInt8](data[1..<3]))
        return (Int(val), 3)
    }
    
    throw NFCSDKError.CannotDecodeASN1Length
    
}

@available(iOS 13, macOS 10.15, *)
public func toAsn1Length(_ data : Int) throws -> [UInt8] {
    if data < 0x80 {
        return hexRepToBin(String(format:"%02x", data))
    }
    if data >= 0x80 && data <= 0xFF {
        return [0x81] + hexRepToBin( String(format:"%02x",data))
    }
    if data >= 0x0100 && data <= 0xFFFF {
        return [0x82] + hexRepToBin( String(format:"%04x",data))
    }
    
    throw NFCSDKError.InvalidASN1Value
}
        

@available(iOS 13, macOS 10.15, *)
public func calcHash( data: [UInt8], hashAlgorithm: String ) throws -> [UInt8] {
    var ret : [UInt8] = []
    
    let hashAlgorithm = hashAlgorithm.lowercased()
    if hashAlgorithm == "sha1" {
        ret = calcSHA1Hash(data)
    } else if hashAlgorithm == "sha224" {
        ret = calcSHA224Hash(data)
    } else if hashAlgorithm == "sha256" {
        ret = calcSHA256Hash(data)
    } else if hashAlgorithm == "sha384" {
        ret = calcSHA384Hash(data)
    } else if hashAlgorithm == "sha512" {
        ret = calcSHA512Hash(data)
    } else {
        throw NFCSDKError.InvalidHashAlgorithmSpecified
    }
        
    return ret
}


@available(iOS 13, macOS 10.15, *)
public func calcSHA1Hash( _ data: [UInt8] ) -> [UInt8] {
    #if canImport(CryptoKit)
    var sha1 = Insecure.SHA1()
    sha1.update(data: data)
    let hash = sha1.finalize()
    
    return Array(hash)
    #else
    fatalError("Couldn't import CryptoKit")
    #endif
}

@available(iOS 13, macOS 10.15, *)
public func calcSHA224Hash( _ data: [UInt8] ) -> [UInt8] {
    
    var digest = [UInt8](repeating: 0, count:Int(CC_SHA224_DIGEST_LENGTH))
    
    data.withUnsafeBytes {
        _ = CC_SHA224($0.baseAddress, CC_LONG(data.count), &digest)
    }
    return digest
}

@available(iOS 13, macOS 10.15, *)
public func calcSHA256Hash( _ data: [UInt8] ) -> [UInt8] {
    #if canImport(CryptoKit)
    var sha256 = SHA256()
    sha256.update(data: data)
    let hash = sha256.finalize()
    
    return Array(hash)
    #else
    fatalError("Couldn't import CryptoKit")
    #endif
}

@available(iOS 13, macOS 10.15, *)
public func calcSHA512Hash( _ data: [UInt8] ) -> [UInt8] {
    #if canImport(CryptoKit)
    var sha512 = SHA512()
    sha512.update(data: data)
    let hash = sha512.finalize()
    
    return Array(hash)
    #else
    fatalError("Couldn't import CryptoKit")
    #endif
}

@available(iOS 13, macOS 10.15, *)
public func calcSHA384Hash( _ data: [UInt8] ) -> [UInt8] {
    #if canImport(CryptoKit)
    var sha384 = SHA384()
    sha384.update(data: data)
    let hash = sha384.finalize()
    
    return Array(hash)
    #else
    fatalError("Couldn't import CryptoKit")
    #endif
}

