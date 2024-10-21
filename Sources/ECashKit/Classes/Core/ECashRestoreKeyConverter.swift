//
//  ECashRestoreKeyConverter.swift
//  ECashKit
//
//  Created by Sun on 2023/3/31.
//

import Foundation

import BitcoinCore

class ECashRestoreKeyConverter: IRestoreKeyConverter {
    // MARK: Lifecycle

    init() { }

    // MARK: Functions

    public func keysForApiRestore(publicKey: PublicKey) -> [String] {
        [publicKey.hashP2pkh.sw.hex]
    }

    public func bloomFilterElements(publicKey: PublicKey) -> [Data] {
        [publicKey.hashP2pkh, publicKey.raw]
    }
}
