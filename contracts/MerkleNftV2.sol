// contracts/ZkuHwNft.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MerkleNftV2 is ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;
    mapping(uint256 => string) private _tokenURIs;

    bytes32 public merkleRoot;
    bytes32[] public merkleLeaves;
    // The left siblings for the next leaf to update the Merkle tree.
    // We keep this mapping in storage to add new leaf to Merkle tree with O(log(n)) time complexity.
    mapping(uint8 => bytes32) public nextLeftSiblings;

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

        require(_exists(newId), "URI set of nonexistent token");
        // Set token URI on chain.
        _tokenURIs[newId] = generateTokenURI(newId, description);

        // Commit to merkle
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
        addLeaf(newLeaf);
    }

    function addLeaf(bytes32 leaf) internal {
        merkleLeaves.push(leaf);

        // index of the new leaf.
        uint256 index = merkleLeaves.length - 1;
        // index of the next leaf that will be added next time when addLeaf is called.
        uint256 nextIndex = index + 1;
        // Height of the node.
        uint8 height = 0;
        // Current hash for index.
        bytes32 curHash = leaf;
        // Parent Hash for index.
        bytes32 parentHash;
        while (index > 0) {
            // Using index, and leftSiblings to calculate the hash of parent node
            parentHash = getParentHash(
                index,
                nextLeftSiblings[height],
                curHash
            );

            // When index == nextIndex, the siblings of nextIndex are the same as siblings of index,
            // so no need to update the storage.

            // Udate the left siblings for next index.
            if (index != nextIndex) {
                // index and nextIndex share the same parent, thus, index is the left sibling of nextIndex.
                if (index / 2 == nextIndex / 2) {
                    nextLeftSiblings[height] = curHash;
                }
                // Else nextIndex has no left siblings, delete the storage and return gas.
                else {
                    nextLeftSiblings[height] = bytes32(0);
                }
            }

            // Move index and nextIndex up a layer
            index /= 2;
            nextIndex /= 2;
            height++;
            curHash = parentHash;
        }
        // curHash for index 0 is the updated merkleRoot.
        merkleRoot = curHash;

        // nextIndex > 0 while index == 0 means the nextIndex will increase the height of the
        // current tree merkleRoot will be a left sibling in this case.
        if (nextIndex > 0) {
            nextLeftSiblings[height] = merkleRoot;
        }
    }

    function joinHash(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(left, right));
    }

    function getParentHash(
        uint256 index,
        bytes32 leftSiblingHash,
        bytes32 curHash
    ) internal pure returns (bytes32) {
        // left node, there is no right siblings since the newly added leaf is the right most leaf.
        // So duplicate the current node to the right.
        if (index % 2 == 0) {
            return joinHash(curHash, curHash);
        }
        // right node, read the left node siblings from leftSiblings map using tree height h;
        else {
            require(leftSiblingHash != bytes32(0), "Left sibling is 0!");
            return joinHash(leftSiblingHash, curHash);
        }
    }
}
