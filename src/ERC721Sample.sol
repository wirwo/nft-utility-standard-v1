// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract SimpleERC721 is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 10;
    uint256 private _currentTokenId = 0;

    constructor() ERC721("SimpleERC721", "SERC721") {}

    function mint() external onlyOwner {
        require(_currentTokenId < MAX_SUPPLY, "All tokens have been minted");

        _safeMint(msg.sender, _currentTokenId);
        _currentTokenId = _currentTokenId + 1;
    }
}
