import Foundation
import BitcoinCore
import HsToolKit
import SwiftProtobuf

public class ChronikApi {
    private let url: String
    private let networkManager: NetworkManager

    public init(url: String, logger: Logger? = nil) {
        self.url = url
        networkManager = NetworkManager(interRequestInterval: 0.1, logger: logger)
    }

    private func itemsRecursive(address: String, items: [SyncTransactionItem] = [], pageCount: Int = 1, index: Int = 0) async throws -> [SyncTransactionItem] {
        guard index < pageCount else {
            return items
        }

        let path = "script/p2pkh/\(address)/history"

        var parameters = [String: Any]()
        if index != 0 {
            parameters["page"] = index
        }

        let data: Data
        do {
            data = try await networkManager.fetchData(url: url + path, method: .get, parameters: parameters)
        } catch let error as HsToolKit.NetworkManager.ResponseError {
            if let code = error.statusCode, code == 200, error.rawData == nil {
                return []
            } else {
                throw error
            }
        }

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

        return try await itemsRecursive(address: address, items: items, pageCount: numPages, index: index + 1)
    }

    private func transactionsRecursive(items: [SyncTransactionItem] = [], addresses: [String], index: Int = 0) async throws -> [SyncTransactionItem] {
        guard index < addresses.count else {
            return items
        }

        let newItems = try await itemsRecursive(address: addresses[index])

        return try await transactionsRecursive(items: items + newItems, addresses: addresses, index: index + 1)
    }

}

extension ChronikApi: ISyncTransactionApi {

    public func transactions(addresses: [String]) async throws -> [SyncTransactionItem] {
        try await transactionsRecursive(addresses: addresses)
    }

}
