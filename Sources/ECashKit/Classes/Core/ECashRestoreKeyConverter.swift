//
//  ECashRestoreKeyConverter.swift
//  ECashKit
//
//  Created by Sun on 2024/8/21.
//

import Foundation

import BitcoinCore

class ECashRestoreKeyConverter: IRestoreKeyConverter {
    init() {}

    public func keysForApiRestore(publicKey: PublicKey) -> [String] {
        [publicKey.hashP2pkh.ww.hex]
    }

    public func bloomFilterElements(publicKey: PublicKey) -> [Data] {
        [publicKey.hashP2pkh, publicKey.raw]
    }
}
