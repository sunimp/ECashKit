//
//  ECashAdapter.swift
//  ECashKit-Example
//
//  Created by Sun on 2024/8/21.
//

import Foundation

import BitcoinCore
import ECashKit
import HDWalletKit
import SWToolKit

class ECashAdapter: BaseAdapter {
    let eCashKit: Kit

    init(words: [String], testMode: Bool, syncMode: BitcoinCore.SyncMode, logger: Logger) {
        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet
        guard let seed = Mnemonic.seed(mnemonic: words) else {
            fatalError("Cant make Seed")
        }
        eCashKit = try! Kit(seed: seed, walletID: "walletID", syncMode: syncMode, networkType: networkType, logger: logger.scoped(with: "ECashKit"))

        super.init(name: "eCash", coinCode: "XEC", abstractKit: eCashKit)
        eCashKit.delegate = self
    }

    class func clear() {
        try? Kit.clear()
    }
}

extension ECashAdapter: BitcoinCoreDelegate {
    func transactionsUpdated(inserted _: [TransactionInfo], updated _: [TransactionInfo]) {
        transactionsSubject.send()
    }

    func transactionsDeleted(hashes _: [String]) {
        transactionsSubject.send()
    }

    func balanceUpdated(balance _: BalanceInfo) {
        balanceSubject.send()
    }

    func lastBlockInfoUpdated(lastBlockInfo _: BlockInfo) {
        lastBlockSubject.send()
    }

    public func kitStateUpdated(state _: BitcoinCore.KitState) {
        syncStateSubject.send()
    }
}
