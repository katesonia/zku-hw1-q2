// contracts/ZkuHwNft.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract ZkuHwNft is ERC721URIStorage {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    constructor() ERC721("ZkuHwNft", "ZKH") {}

    // Mint nft to any address 'to' with a description string.
    function mint(address to, string memory description)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newId = _tokenIds.current();
        // Mint token newId.
        _mint(to, newId);
        // Set token URI on chain.
        _setTokenURI(newId, generateTokenURI(newId, description));

        return newId;
    }

    // Generates token uri.
    function generateTokenURI(uint256 tokenId, string memory description)
        internal
        pure
        returns (string memory)
    {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "ZkuHwNft #',
            tokenId.toString(),
            '"',
            '"description": "',
            description,
            '"',
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }
}
