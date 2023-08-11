# ERC-721 Utility Standard

A solidity-based NFT utility management standard by [0xWira](https://www.prawira.xyz)

## Overview

NFTUtilities offers a comprehensive platform for NFT token holders to seamlessly assign, modify, and oversee utilities linked to their assets. This standard is compatible with leading web3 wallets like Phantom, Metamask, and Rainbow, so that utilities can be easily discovered by the holders. This framework is for NFT projects that wants to give practical rewards to their community beyond mere ownership of the token.

Used Paradigm's [Foundry](https://github.com/foundry-rs/foundry)

## Key Features

**Utility Management:** Assign utilities to specific NFTs or all NFTs.

**Utility Tracking:** Keep track of utility uses, expiration, and deletion statuses.

**Secure:** Only the NFT holder can add or modify the utilities tied to their tokens.

**Expandable:** Utilities are defined in a separate library, making it easier to expand upon or modify the utility structure.

## Usage

**1. Adding Utilities:**

- For specific tokens:

```JavaScript
addUtility(tokenIds[], utilityURI, uses, utilityExpiry)
```

- For all tokens:

```JavaScript
addUtilityToAll(utilityURI, uses, utilityExpiry)
```

**2. Editing Utilities:**

```JavaScript
editUtility(utilityId, newUtilityURI, newUses, newExpiry)
```

**3. Deleting Utilities:**

```JavaScript
deleteUtility(utilityId)
```

**4. Using a Utility:**

```JavaScript
useUtility(tokenId, utilityId)
```

**5. Getting Utilities for a Token:**

```JavaScript
getUtility(tokenId)
```

## Tests
