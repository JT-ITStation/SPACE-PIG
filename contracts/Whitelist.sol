// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "@openzeppelin/contracts/access/Ownable.sol";

contract WhitelistContract is Ownable {
 // contract code
     struct WhitelistEntry {
        bool isApproved;
        uint256 reservedQuantity;
    }
    mapping(address => WhitelistEntry) public whitelist;

    constructor ()Ownable(msg.sender){}
    
    function addToWhitelist(address _address, uint256 reservedQty)
        public
        onlyOwner
    {
        whitelist[_address] = WhitelistEntry(true, reservedQty);
    }

    function refreshQuantity(address _address, uint256 usedQty)
        public
        onlyOwner
    {
        whitelist[_address].reservedQuantity = whitelist[_address].reservedQuantity - usedQty;
    }
    
    function flipWhitelistApproveStatus(address _address) public onlyOwner {
        whitelist[_address].isApproved = !whitelist[_address].isApproved;
    }

    function addressIsPresaleApproved(address _address)
        public
        view
        returns (bool)
    {
        return whitelist[_address].isApproved;
    }

    
    function getReservedPresaleQuantity(address _address)
        public
        view
        returns (uint256)
    {
        return whitelist[_address].reservedQuantity;
    }

    function initPresaleWhitelist(
        address[] memory addr,
        uint256[] memory quantities
    ) public onlyOwner {
        for (uint256 i = 0; i < addr.length; i++) {
            whitelist[addr[i]] = WhitelistEntry(true, quantities[i]);
        }
    }
}