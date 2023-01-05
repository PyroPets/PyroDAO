// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../pyro/IPyroBase.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";

contract PyroDAOToken is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    EIP712,
    ERC721Votes
{
    IPyroBase public immutable base;

    constructor(address pyroBase)
        ERC721("Pyro DAO Token", "PDAO")
        EIP712("Pyro DAO Token", "1")
    {
        base = IPyroBase(pyroBase);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://dao.pyropets.org/api/metadata/";
    }

    function reclaim(address to, uint256 tokenId) public {
        address tokenOwner = base.ownerOf(tokenId);
        require(
            to == tokenOwner ||
                base.isApprovedForAll(tokenOwner, to) ||
                to == base.getApproved(tokenId),
            "PyroDAOToken: Not token owner or approved"
        );
        if (_exists(tokenId) && ownerOf(tokenId) != to) {
            _burn(tokenId);
        }
        if (!_exists(tokenId)) {
            _safeMint(to, tokenId);
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
