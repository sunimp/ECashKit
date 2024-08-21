//
//  MainNet.swift
//  ECashKit
//
//  Created by Sun on 2024/8/21.
//

import Foundation

import BitcoinCore

public class MainNet: INetwork {
    public let bundleName = "ECash"

    public let maxBlockSize: UInt32 = 32 * 1024 * 1024
    public let pubKeyHash: UInt8 = 0x00
    public let privateKey: UInt8 = 0x80
    public let scriptHash: UInt8 = 0x05
    public let bech32PrefixPattern: String = "ecash"
    public let xPubKey: UInt32 = 0x0488_B21E
    public let xPrivKey: UInt32 = 0x0488_ADE4
    public let magic: UInt32 = 0xE3E1_F3E8
    public let port = 8333
    public let coinType: UInt32 = 899
    public let sigHash: SigHashType = .bitcoinCashAll
    public var syncableFromApi: Bool = true
    public var blockchairChainId: String = "ecash"

    public let dnsSeeds = [
        "x5.seed.bitcoinabc.org", // Bitcoin ABC seeder
        "btccash-seeder.bitcoinunlimited.info", // BU backed seeder
        "x5.seeder.jasonbcox.com", // Jason B. Cox
        "seed.deadalnix.me", // Amaury SÉCHET
        "seed.bchd.cash", // BCHD
        "x5.seeder.fabien.cash", // Fabien
    ]

    public let dustRelayTxFee = 1000

    public init() {}
}
