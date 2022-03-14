// contracts/ZkuHwNft.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MerkleNftV1 is ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;
    mapping(uint256 => string) private _tokenURIs;

    bytes32 public merkleRoot;
    bytes32[] public merkleLeaves;

    constructor() ERC721("MerkleNftV1", "MKL1") {}

    // Mint nft to any address 'to' with a description string.
    function mint(address to, string memory description)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newId = _tokenIds.current();
        // Mint token newId.
        _mint(to, newId);

        require(_exists(newId), "URI set of nonexistent token");
        // Set token URI on chain.
        _tokenURIs[newId] = generateTokenURI(newId, description);

        // Commit to merkle tree.
        commitMerkleTree(newId, msg.sender, to);
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

    function commitMerkleTree(
        uint256 tokenId,
        address minter,
        address receiver
    ) internal {
        require(tokenId >= merkleLeaves.length, "already in the merkle tree");
        bytes32 newLeaf = keccak256(
            abi.encodePacked(minter, receiver, tokenId, _tokenURIs[tokenId])
        );
        merkleLeaves.push(newLeaf);
        merkleRoot = buildMerkleTree(merkleLeaves);
    }

    // Given an non-empty leaves, build a merkle tree and return root.
    function buildMerkleTree(bytes32[] memory leaves)
        internal
        pure
        returns (bytes32)
    {
        require(
            leaves.length > 0,
            "cannot build merkle tree with empty leaves"
        );

        uint256 size = 1;
        // Number of leaves for a smallest perfectly balanced binary tree that
        // include the merkle leaves.
        while (size < leaves.length) {
            size *= 2;
        }

        // If number of leaves is not 2**n, pad the last element util the paddedLeaves has a length of 2**n.
        bytes32[] memory paddedLeaves = new bytes32[](size);
        for (uint256 i = 0; i < size; i++) {
            paddedLeaves[i] = i < leaves.length
                ? leaves[i]
                : leaves[leaves.length - 1];
        }

        // Build a merkel tree for paddedLeaves in place.
        for (size /= 2; size > 1; size /= 2) {
            for (uint256 i = 0; i < size; i++) {
                paddedLeaves[i] = joinHash(
                    paddedLeaves[2 * i],
                    paddedLeaves[2 * i + 1]
                );
            }
        }
        // Returns merkle tree root.
        return paddedLeaves[0];
    }

    function joinHash(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(left, right));
    }
}
