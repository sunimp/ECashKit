//
//  Kit.swift
//  ECashKit
//
//  Created by Sun on 2023/3/31.
//

import Foundation

import BigInt
import BitcoinCashKit
import BitcoinCore
import HDWalletKit
import SWToolKit

// MARK: - Kit

public class Kit: AbstractKit {
    // MARK: Nested Types

    public enum NetworkType {
        case mainNet
        case testNet

        // MARK: Computed Properties

        var network: INetwork {
            switch self {
            case .mainNet:
                MainNet()
            case .testNet:
                TestNet()
            }
        }

        var description: String {
            switch self {
            case .mainNet:
                "mainNet"
            case .testNet:
                "testNet"
            }
        }
    }

    // MARK: Static Properties

    private static let name = "ECashKit"
    private static let svChainForkHeight = 556767 // 2018 November 14
    private static let bchaChainForkHeight = 661648 // 2020 November 15, 14:13 GMT
    private static let abcChainForkBlockHash = "0000000000000000004626ff6e3b936941d341c5932ece4357eeccac44e6d56c"
        .reversedData!
    private static let bchaChainForkBlockHash = "000000000000000004284c9d8b2c8ff731efeaec6be50729bdc9bd07f910757d"
        .reversedData!

    private static let legacyHeightInterval = 2016 // Default block count in difficulty change circle ( Bitcoin )
    private static let legacyTargetSpacing = 10 * 60 // Time to mining one block ( 10 min. Bitcoin )
    private static let legacyMaxTargetBits = 0x1D00FFFF // Initially and max. target difficulty for blocks

    private static let heightInterval = 144 // Blocks count in window for calculating difficulty ( ECashKit )
    private static let targetSpacing = 10 * 60 // Time to mining one block ( 10 min. same as Bitcoin )
    private static let maxTargetBits = 0x1D00FFFF // Initially and max. target difficulty for blocks

    // MARK: Computed Properties

    public weak var delegate: BitcoinCoreDelegate? {
        didSet {
            bitcoinCore.delegate = delegate
        }
    }

    // MARK: Lifecycle

    public convenience init(
        seed: Data,
        walletID: String,
        syncMode: BitcoinCore.SyncMode = .api,
        networkType: NetworkType = .mainNet,
        confirmationsThreshold: Int = 6,
        logger: Logger?
    ) throws {
        let masterPrivateKey = HDPrivateKey(seed: seed, xPrivKey: Purpose.bip44.rawValue)

        try self.init(
            extendedKey: .private(key: masterPrivateKey),
            walletID: walletID,
            syncMode: syncMode,
            networkType: networkType,
            confirmationsThreshold: confirmationsThreshold,
            logger: logger
        )
    }

    public convenience init(
        extendedKey: HDExtendedKey,
        walletID: String,
        syncMode: BitcoinCore.SyncMode = .api,
        networkType: NetworkType = .mainNet,
        confirmationsThreshold: Int = 6,
        logger: Logger?
    ) throws {
        let network = networkType.network
        try self.init(
            extendedKey: extendedKey,
            watchAddressPublicKey: nil,
            walletID: walletID,
            syncMode: syncMode,
            networkType: networkType,
            confirmationsThreshold: confirmationsThreshold,
            logger: logger
        )

        // extending BitcoinCore
        let bech32AddressConverter = CashBech32AddressConverter(prefix: network.bech32PrefixPattern)
        bitcoinCore.prepend(addressConverter: bech32AddressConverter)
    }

    public convenience init(
        watchAddress: String,
        walletID: String,
        syncMode: BitcoinCore.SyncMode = .api,
        networkType: NetworkType = .mainNet,
        confirmationsThreshold: Int = 6,
        logger: Logger?
    ) throws {
        let network = networkType.network
        let base58AddressConverter = Base58AddressConverter(
            addressVersion: network.pubKeyHash,
            addressScriptVersion: network.scriptHash
        )
        let bech32AddressConverter = CashBech32AddressConverter(prefix: network.bech32PrefixPattern)
        let parserChain = AddressConverterChain()
        parserChain.prepend(addressConverter: base58AddressConverter)
        parserChain.prepend(addressConverter: bech32AddressConverter)

        let address = try parserChain.convert(address: watchAddress)
        let publicKey = try WatchAddressPublicKey(data: address.lockingScriptPayload, scriptType: address.scriptType)

        try self.init(
            extendedKey: nil,
            watchAddressPublicKey: publicKey,
            walletID: walletID,
            syncMode: syncMode,
            networkType: networkType,
            confirmationsThreshold: confirmationsThreshold,
            logger: logger
        )

        bitcoinCore.prepend(addressConverter: bech32AddressConverter)
    }

    private init(
        extendedKey: HDExtendedKey?,
        watchAddressPublicKey: WatchAddressPublicKey?,
        walletID: String,
        syncMode: BitcoinCore.SyncMode = .api,
        networkType: NetworkType = .mainNet,
        confirmationsThreshold: Int = 6,
        logger: Logger?
    ) throws {
        let network = networkType.network
        let validScheme =
            switch networkType {
            case .mainNet:
                "ecash"
            case .testNet:
                "ecashtest"
            }

        let logger = logger ?? Logger(minLogLevel: .verbose)
        let databaseFilePath = try DirectoryHelper.directoryURL(for: Kit.name)
            .appendingPathComponent(Kit.databaseFileName(
                walletID: walletID,
                networkType: networkType,
                syncMode: syncMode
            )).path
        let storage = GrdbStorage(databaseFilePath: databaseFilePath)
        let apiSyncStateManager = ApiSyncStateManager(
            storage: storage,
            restoreFromApi: network.syncableFromApi && syncMode != BitcoinCore.SyncMode.full
        )

        let apiTransactionProvider: IApiTransactionProvider
        switch networkType {
        case .mainNet:
            let apiTransactionProviderURL = "https://chronik.fabien.cash/"

            if case .blockchair = syncMode {
                let blockchairApi = BlockchairApi(chainID: network.blockchairChainID, logger: logger)
                let blockchairBlockHashFetcher = BlockchairBlockHashFetcher(blockchairApi: blockchairApi)
                let blockchairProvider = BlockchairTransactionProvider(
                    blockchairApi: blockchairApi,
                    blockHashFetcher: blockchairBlockHashFetcher
                )
                let chronikApiProvider = ChronikApi(url: apiTransactionProviderURL, logger: logger)

                apiTransactionProvider = BiApiBlockProvider(
                    restoreProvider: chronikApiProvider,
                    syncProvider: blockchairProvider,
                    apiSyncStateManager: apiSyncStateManager
                )
            } else {
                apiTransactionProvider = ChronikApi(url: apiTransactionProviderURL, logger: logger)
            }

        case .testNet:
            apiTransactionProvider = ChronikApi(url: "", logger: logger)
        }

        let paymentAddressParser = PaymentAddressParser(validScheme: validScheme, removeScheme: false)
        let difficultyEncoder = DifficultyEncoder()

        let blockValidatorSet = BlockValidatorSet()
        blockValidatorSet.add(blockValidator: ProofOfWorkValidator(difficultyEncoder: difficultyEncoder))

        let blockValidatorChain = BlockValidatorChain()
        let coreBlockHelper = BlockValidatorHelper(storage: storage)
        let blockHelper = BitcoinCashBlockValidatorHelper(coreBlockValidatorHelper: coreBlockHelper)

        let daaValidator = DAAValidator(
            encoder: difficultyEncoder,
            blockHelper: blockHelper,
            targetSpacing: Kit.targetSpacing,
            heightInterval: Kit.heightInterval
        )
        let asertValidator = ASERTValidator(encoder: difficultyEncoder)

        switch networkType {
        case .mainNet:
            blockValidatorChain.add(blockValidator: ForkValidator(
                concreteValidator: asertValidator,
                forkHeight: Kit.bchaChainForkHeight,
                expectedBlockHash: Kit.bchaChainForkBlockHash
            ))
            blockValidatorChain.add(blockValidator: asertValidator)
            blockValidatorChain.add(blockValidator: ForkValidator(
                concreteValidator: daaValidator,
                forkHeight: Kit.svChainForkHeight,
                expectedBlockHash: Kit.abcChainForkBlockHash
            ))
            blockValidatorChain.add(blockValidator: daaValidator)
            blockValidatorChain.add(blockValidator: LegacyDifficultyAdjustmentValidator(
                encoder: difficultyEncoder,
                blockValidatorHelper: coreBlockHelper,
                heightInterval: Kit.legacyHeightInterval,
                targetTimespan: Kit.legacyTargetSpacing * Kit.legacyHeightInterval,
                maxTargetBits: Kit.legacyMaxTargetBits
            ))
            blockValidatorChain.add(blockValidator: EDAValidator(
                encoder: difficultyEncoder,
                blockHelper: blockHelper,
                blockMedianTimeHelper: BlockMedianTimeHelper(storage: storage),
                maxTargetBits: Kit.legacyMaxTargetBits
            ))

        case .testNet: ()
            // not use test validators
        }

        blockValidatorSet.add(blockValidator: blockValidatorChain)

        let bitcoinCore = try BitcoinCoreBuilder(logger: logger)
            .set(network: network)
            .set(apiTransactionProvider: apiTransactionProvider)
            .set(checkpoint: Checkpoint.resolveCheckpoint(network: network, syncMode: syncMode, storage: storage))
            .set(apiSyncStateManager: apiSyncStateManager)
            .set(extendedKey: extendedKey)
            .set(watchAddressPublicKey: watchAddressPublicKey)
            .set(paymentAddressParser: paymentAddressParser)
            .set(walletID: walletID)
            .set(confirmationsThreshold: confirmationsThreshold)
            .set(peerSize: 10)
            .set(purpose: .bip44)
            .set(syncMode: syncMode)
            .set(storage: storage)
            .set(blockValidator: blockValidatorSet)
            .build()

        super.init(bitcoinCore: bitcoinCore, network: network)

        bitcoinCore.add(restoreKeyConverter: ECashRestoreKeyConverter())
    }
}

extension Kit {
    public static func clear(exceptFor walletIDsToExclude: [String] = []) throws {
        try DirectoryHelper.removeAll(inDirectory: Kit.name, except: walletIDsToExclude)
    }

    private static func databaseFileName(
        walletID: String,
        networkType: NetworkType,
        syncMode: BitcoinCore.SyncMode
    )
        -> String {
        "\(walletID)-\(networkType.description)-\(syncMode)"
    }
    
    private static func addressConverter(network: INetwork) -> AddressConverterChain {
        let addressConverter = AddressConverterChain()
        addressConverter.prepend(addressConverter: CashBech32AddressConverter(prefix: network.bech32PrefixPattern))

        return addressConverter
    }

    public static func firstAddress(seed: Data, networkType: NetworkType) throws -> Address {
        let network = networkType.network

        return try BitcoinCore.firstAddress(
            seed: seed,
            purpose: Purpose.bip44,
            network: network,
            addressCoverter: addressConverter(network: network)
        )
    }
    
    public static func firstAddress(extendedKey: HDExtendedKey, networkType: NetworkType) throws -> Address {
        let network = networkType.network
        
        return try BitcoinCore.firstAddress(
            extendedKey: extendedKey,
            purpose: Purpose.bip44,
            network: network,
            addressCoverter: addressConverter(network: network)
        )
    }
}
