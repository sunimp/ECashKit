//
//  TestNet.swift
//  ECashKit
//
//  Created by Sun on 2024/8/21.
//

import Foundation

import BitcoinCore

class TestNet: INetwork {
    let bundleName = "ECash"

    let maxBlockSize: UInt32 = 32 * 1024 * 1024
    let pubKeyHash: UInt8 = 0x6F
    let privateKey: UInt8 = 0xEF
    let scriptHash: UInt8 = 0xC4
    let bech32PrefixPattern = "ecashtest"
    let xPubKey: UInt32 = 0x0435_87CF
    let xPrivKey: UInt32 = 0x0435_8394
    let magic: UInt32 = 0xF4E5_F3F4
    let port = 18333
    let coinType: UInt32 = 1
    let sigHash: SigHashType = .bitcoinCashAll
    var syncableFromApi = true
    var blockchairChainID = ""

    let dnsSeeds = [
        "testnet-seed.bitcoinabc.org",
        "testnet-seed-abc.bitcoinforks.org",
    ]

    let dustRelayTxFee = 1000 // https://github.com/Bitcoin-ABC/bitcoin-abc/blob/master/src/policy/policy.h#L78
}
