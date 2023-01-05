// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IPyroBase is IERC721Enumerable {
    function generationOfPyro(uint256 tokenId) external view returns (uint256);

    function getPyro(uint256 id)
        external
        view
        returns (
            uint256 donorA,
            uint256 donorB,
            uint256 generation,
            string memory name,
            uint256 ignitionTime,
            uint256 nextPyroGenesis,
            uint256 pyroGenesisCount,
            uint256 stokingWith,
            uint8 hunger,
            uint8 eyes,
            uint8 snout,
            uint8 color
        );

    function burn(uint256 tokenId) external;

    function play(uint256 tokenId) external;

    function feed(uint256 tokenId, uint8 amount) external;

    function setColor(uint256 tokenId, uint8 color) external;

    function setName(uint256 tokenId, string calldata name) external;

    function levelUp(uint256 tokenId, uint256 amount) external;
}
