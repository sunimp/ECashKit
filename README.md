# ECashKit.Swift

`ECashKit.Swift` is a package that extends [BitcoinCore.Swift](https://github.com/sunimp/BitcoinCore.Swift) and makes it usable with `BitcoinCash (ABC)` Mainnet and Testnet networks. 

## Features

- [x] `Bech32`
- [x] Validation of BCH hard forks
- [x] `ASERT`, `DAA`, `EDA` validations


## Usage

Because ECashKit is a fork of BitcoinCash, the usage of this package does not differ much from `BitcoinKit.Swift`. So here, we only describe some differences between these packages. For more usage documentation, please see [BitcoinKit.Swift](https://github.com/sunimp/BitcoinKit.Swift)

### Initialization

All ECashKit wallets use default [BIP44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki) derivation path where *coinType* is `899` according to [SLIP44](https://github.com/satoshilabs/slips/blob/master/slip-0044.md).

```swift
let seed = Mnemonic.seed(mnemonic: [""], passphrase: "")!

let ECashKit = try ECashKit.Kit(
        seed: seed,
        walletId: "unique_wallet_id",
        syncMode: .full,
        networkType: .mainNet(),
        confirmationsThreshold: 1,
        logger: nil
)
```
## Prerequisites

* Xcode 15.0+
* Swift 5.5+
* iOS 13+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/sunimp/ECashKit.Swift.git", .upToNextMajor(from: "3.0.3"))
]
```

## Example Project

All features of the library are used in example project. It can be referred as a starting point for usage of the library.

## License

The `ECashKit` toolkit is open source and available under the terms of the [MIT License](https://github.com/sunimp/ECashKit.Swift/blob/master/LICENSE).

