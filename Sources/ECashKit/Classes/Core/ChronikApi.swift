import Foundation
import BitcoinCore
import HsToolKit
import RxSwift
import SwiftProtobuf

public class ChronikApi {
    private let url: String
    private let networkManager: NetworkManager

    public init(url: String, logger: Logger? = nil) {
        self.url = url
        networkManager = NetworkManager(logger: logger)
    }

    private func itemsRecursive(address: String, items: [SyncTransactionItem] = [], pageCount: Int = 1, index: Int = 0) -> Single<[SyncTransactionItem]> {
        guard index < pageCount else {
            return .just(items)
        }

        let path = "script/p2pkh/\(address)/history"

        var parameters = [String: Any]()
        if index != 0 {
            parameters["page"] = index
        }

        let request = networkManager.session.request(url + path, method: .get, parameters: parameters)
        let single: Single<Data> = networkManager.single(request: request, postDelay: 0.1)

        return single.flatMap { [weak self] data -> Single<[SyncTransactionItem]> in
            var items = items
            var numPages = 1
            do {
                let historyPage = try Chronik_TxHistoryPage(contiguousBytes: data)
                numPages = Int(historyPage.numPages)
                items.append(contentsOf: historyPage.txs.map {
                    SyncTransactionItem(
                            hash: $0.block.hash.hs.reversedHex,
                            height: Int($0.block.height),
                            txOutputs: $0.outputs.map {
                                SyncTransactionOutputItem(
                                        script: $0.outputScript.hs.reversedHex,
                                        address: ""
                                )
                            })
                })
            } catch {
                print("Error: \(error))")
            }

            return self?.itemsRecursive(address: address, items: items, pageCount: numPages, index: index + 1) ?? .just(items)
        }
    }

    private func transactionsRecursive(items: [SyncTransactionItem] = [], addresses: [String], index: Int = 0) -> Single<[SyncTransactionItem]> {
        guard index < addresses.count else {
            return .just(items)
        }

        return itemsRecursive(address: addresses[index]).flatMap { [weak self] newItems in
            self?.transactionsRecursive(items: items + newItems, addresses: addresses, index: index + 1) ?? .just(items)
        }
    }

}

extension ChronikApi: ISyncTransactionApi {

    public func getTransactions(addresses: [String]) -> Single<[SyncTransactionItem]> {
        transactionsRecursive(addresses: addresses)
    }

}

struct DataMapper: IApiMapper {

    public func map(statusCode: Int, data: Any?) throws -> Data {
        (data as? Data) ?? Data()
    }

}
