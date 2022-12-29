// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract PyroVault is Ownable, ERC721Holder {
    fallback() external payable {}

    receive() external payable {}

    function executeTransaction(
        address payable _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        (bool success, ) = _to.call{value: _value}(_data);
        require(success, "ControlledGovernor: Tx failed");
    }
}
