//
//  Extensions.swift
//  Seer
//
//  Created by Jacob Davis on 10/30/22.
//

import Foundation
import NostrKit
import CommonCrypto
import secp256k1

extension String {
    
    func isValidName() -> Bool {
        if self.isEmpty {
            return false
        }
        let nameRegex = #"^[\w+\-]*$"#
        return self.range(of: nameRegex, options: [.regularExpression]) != nil
    }
    
    func removingUrls() -> String {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return self
        }
        return detector.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count), withTemplate: "")
    }
    
}

extension URL {
    public func isImageType() -> Bool {
        let imageFormats = ["jpg", "png", "gif"]
        let extensi = self.pathExtension
        return imageFormats.contains(extensi)
    }
    public func isVideoType() -> Bool {
        let videoFormats = ["mp4", "mov"]
        let extensi = self.pathExtension
        return videoFormats.contains(extensi)
    }
}

extension Data {
    func hexEncodedString() -> String {
        let hexDigits = Array("0123456789abcdef".utf16)
        var hexChars = [UTF16.CodeUnit]()
        hexChars.reserveCapacity(count * 2)

        for byte in self {
            let (index1, index2) = Int(byte).quotientAndRemainder(dividingBy: 16)
            hexChars.append(hexDigits[index1])
            hexChars.append(hexDigits[index2])
        }

        return String(utf16CodeUnits: hexChars, count: hexChars.count)
    }
}

extension String {
    /// A data representation of the hexadecimal bytes in this string.
    func hexDecodedData() -> Data {
        // Get the UTF8 characters of this string
        let chars = Array(utf8)
        
        // Keep the bytes in an UInt8 array and later convert it to Data
        var bytes = [UInt8]()
        bytes.reserveCapacity(count / 2)
        
        // It is a lot faster to use a lookup map instead of strtoul
        let map: [UInt8] = [
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, // 01234567
            0x08, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 89:;<=>?
            0x00, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x00, // @ABCDEFG
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  // HIJKLMNO
        ]
        
        // Grab two characters at a time, map them and turn it into a byte
        for i in stride(from: 0, to: count, by: 2) {
            let index1 = Int(chars[i] & 0x1F ^ 0x10)
            let index2 = Int(chars[i + 1] & 0x1F ^ 0x10)
            bytes.append(map[index1] << 4 | map[index2])
        }
        
        return Data(bytes)
    }
}

extension KeyPair {

    static func decodeBech32(key: String) -> String? {
        guard let decoded = try? bech32_decode(key) else {
            return nil
        }
        
        let hexed = decoded.data.hexEncodedString()
        if decoded.hrp == "npub" {
            return hexed
        } else if decoded.hrp == "nsec" {
            return hexed
        }
        
        return nil
    }

    static func bech32PrivateKey(fromHexPrivateKey privateKey: String) -> String? {
        return bech32_encode(hrp: "nsec", privateKey.hexDecodedData().bytes)
    }

    static func bech32PublicKey(fromHexPublicKey publicKey: String) -> String? {
        return bech32_encode(hrp: "npub", publicKey.hexDecodedData().bytes)
    }
    
    static func decrypt_dm(_ privkey: String?, pubkey: String, content: String) -> String? {
        guard let privkey = privkey else {
            return nil
        }
        guard let shared_sec = get_shared_secret(privkey: privkey, pubkey: pubkey) else {
            return nil
        }
        guard let dat = decode_dm_base64(content) else {
            return nil
        }
        guard let dat = aes_decrypt(data: dat.content, iv: dat.iv, shared_sec: shared_sec) else {
            return nil
        }
        return String(data: dat, encoding: .utf8)
    }


    static func get_shared_secret(privkey: String, pubkey: String) -> [UInt8]? {
        guard let privkey_bytes = try? privkey.bytes else {
            return nil
        }
        guard var pk_bytes = try? pubkey.bytes else {
            return nil
        }
        pk_bytes.insert(2, at: 0)
        
        var publicKey = secp256k1_pubkey()
        var shared_secret = [UInt8](repeating: 0, count: 32)

        var ok =
            secp256k1_ec_pubkey_parse(
                try! secp256k1.Context.create(),
                &publicKey,
                pk_bytes,
                pk_bytes.count) != 0

        if !ok {
            return nil
        }

        ok = secp256k1_ecdh(
            try! secp256k1.Context.create(),
            &shared_secret,
            &publicKey,
            privkey_bytes, {(output,x32,_,_) in
                memcpy(output,x32,32)
                return 1
            }, nil) != 0

        if !ok {
            return nil
        }

        return shared_secret
    }

    struct DirectMessageBase64 {
        let content: [UInt8]
        let iv: [UInt8]
    }

    static func encode_dm_base64(content: [UInt8], iv: [UInt8]) -> String {
        let content_b64 = base64_encode(content)
        let iv_b64 = base64_encode(iv)
        return content_b64 + "?iv=" + iv_b64
    }

    static func decode_dm_base64(_ all: String) -> DirectMessageBase64? {
        let splits = Array(all.split(separator: "?"))

        if splits.count != 2 {
            return nil
        }

        guard let content = base64_decode(String(splits[0])) else {
            return nil
        }

        var sec = String(splits[1])
        if !sec.hasPrefix("iv=") {
            return nil
        }

        sec = String(sec.dropFirst(3))
        guard let iv = base64_decode(sec) else {
            return nil
        }

        return DirectMessageBase64(content: content, iv: iv)
    }

    static func base64_encode(_ content: [UInt8]) -> String {
        return Data(content).base64EncodedString()
    }

    static func base64_decode(_ content: String) -> [UInt8]? {
        guard let dat = Data(base64Encoded: content) else {
            return nil
        }
        return dat.bytes
    }

    static func aes_decrypt(data: [UInt8], iv: [UInt8], shared_sec: [UInt8]) -> Data? {
        return aes_operation(operation: CCOperation(kCCDecrypt), data: data, iv: iv, shared_sec: shared_sec)
    }

    static func aes_encrypt(data: [UInt8], iv: [UInt8], shared_sec: [UInt8]) -> Data? {
        return aes_operation(operation: CCOperation(kCCEncrypt), data: data, iv: iv, shared_sec: shared_sec)
    }

    static func aes_operation(operation: CCOperation, data: [UInt8], iv: [UInt8], shared_sec: [UInt8]) -> Data? {
        let data_len = data.count
        let bsize = kCCBlockSizeAES128
        let len = Int(data_len) + bsize
        var decrypted_data = [UInt8](repeating: 0, count: len)

        let key_length = size_t(kCCKeySizeAES256)
        if shared_sec.count != key_length {
            assert(false, "unexpected shared_sec len: \(shared_sec.count) != 32")
            return nil
        }

        let algorithm: CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options:   CCOptions   = UInt32(kCCOptionPKCS7Padding)

        var num_bytes_decrypted :size_t = 0

        let status = CCCrypt(operation,  /*op:*/
                             algorithm,  /*alg:*/
                             options,    /*options:*/
                             shared_sec, /*key:*/
                             key_length, /*keyLength:*/
                             iv,         /*iv:*/
                             data,       /*dataIn:*/
                             data_len, /*dataInLength:*/
                             &decrypted_data,/*dataOut:*/
                             len,/*dataOutAvailable:*/
                             &num_bytes_decrypted/*dataOutMoved:*/
        )

        if UInt32(status) != UInt32(kCCSuccess) {
            return nil
        }

        return Data(bytes: decrypted_data, count: num_bytes_decrypted)

    }
}
