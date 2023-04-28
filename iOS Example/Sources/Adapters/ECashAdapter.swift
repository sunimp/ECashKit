import ECashKit
import BitcoinCore
import HsToolKit
import HdWalletKit

class ECashAdapter: BaseAdapter {
    let eCashKit: Kit

    init(words: [String], testMode: Bool, syncMode: BitcoinCore.SyncMode, logger: Logger) {
        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet
        guard let seed = Mnemonic.seed(mnemonic: words) else {
            fatalError("Cant make Seed")
        }
        eCashKit = try! Kit(seed: seed, walletId: "walletId", syncMode: syncMode, networkType: networkType, logger: logger.scoped(with: "ECashKit"))

        super.init(name: "eCash", coinCode: "XEC", abstractKit: eCashKit)
        eCashKit.delegate = self
    }

    class func clear() {
        try? Kit.clear()
    }
}

extension ECashAdapter: BitcoinCoreDelegate {

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        transactionsSubject.send()
    }

    func transactionsDeleted(hashes: [String]) {
        transactionsSubject.send()
    }

    func balanceUpdated(balance: BalanceInfo) {
        balanceSubject.send()
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockSubject.send()
    }

    public func kitStateUpdated(state: BitcoinCore.KitState) {
        syncStateSubject.send()
    }

}
