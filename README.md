# ERC-721 Utility Standard

A solidity-based NFT utility management standard by [0xWira](https://www.prawira.xyz)

## Overview

NFTUtilities offers a comprehensive platform for NFT token holders to seamlessly assign, modify, and oversee utilities linked to their assets. This standard is compatible with web3 wallets like Phantom, Metamask, and Rainbow, so utilities can be easily discovered right on the wallet apps by the holders. This framework is made for NFT projects that wants to give practical rewards to their community beyond mere ownership of the token.

Using Paradigm's [Foundry](https://github.com/foundry-rs/foundry)

## Key Features

**Utility Management:** Assign utilities to specific NFTs or all NFTs.

**Utility Tracking:** Keep track of utility uses, expiration, and deletion statuses.

**Secure:** Only the NFT holder can add or modify the utilities tied to their tokens.

**Expandable:** Utilities are defined in a separate library, making it easier to expand upon or modify the utility structure.

## Usage

**1. Adding Utilities:**

- For specific tokens:

```Solidity
addUtility(tokenIds[], utilityURI, uses, utilityExpiry)
```

- For all tokens:

```Solidity
addUtilityToAll(utilityURI, uses, utilityExpiry)
```

**2. Editing Utilities:**

```Solidity
editUtility(utilityId, newUtilityURI, newUses, newExpiry)
```

**3. Deleting Utilities:**

```Solidity
deleteUtility(utilityId)
```

**4. Using a Utility:**

```Solidity
useUtility(tokenId, utilityId)
```

**5. Getting Utilities for a Token:**

```Solidity
getUtility(tokenId)
```

## Tests

Tests are located in the `tests/` directory.
