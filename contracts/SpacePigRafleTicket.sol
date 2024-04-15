// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

import "./rarible/impl/RoyaltiesV2Impl.sol";
import "./rarible/LibPart.sol";
import "./rarible/LibRoyaltiesV2.sol";

import "./SpacePig.sol";
import "./SpacePigDescendant.sol";

contract SpacePigRafleTicket is     
    ERC721AQueryable,
    Pausable,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    RoyaltiesV2Impl {

    
    uint256 private tokenIdTracker;
    string public baseURI;
    
    modifier onlySPIGD() {
        require(msg.sender == address(SPIGD), "403");
        _;
    }

    struct family{
        uint256 grdpa;
        uint256 gdrma;
        uint256 father;
        uint256 mother;
        uint256 son;
        uint256 daughter;
        bool isGenesisFather;
        bool isGenesisMother;        
    }
    mapping(uint256 => family) private families;


    //tableau des collections

    SpacePigDescendant private SPIGD;

    constructor() ERC721A("SPIGRafleTicket", "SPIGRT") Ownable(msg.sender) {
        _setDefaultRoyalty(msg.sender, 750);
        _pause();
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override (ERC721A,IERC721A)
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
    
  
    function setSPIGD(SpacePigDescendant _SPIGD) public onlyOwner {
        SPIGD = _SPIGD;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function walletOfOwner(address _owner_loc)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner_loc);
        if (tokenCount == 0) return new uint256[](0);
        uint256[] memory tokensId = new uint256[](tokenCount);
        uint256 index = 0;        
        for (uint256 i = _startTokenId(); i < _nextTokenId(); i++) {
        if (ownerOf(i) == _owner_loc) {
            tokensId[index] = i;
            index++;
            }
        }
        return tokensId;
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function getTicketDetail(uint256 _id)public view returns(uint256[] memory ,bool,bool){
        
        uint256[] memory tempId = new uint256[](6);
        tempId[0]=families[_id].grdpa;
        tempId[1]=families[_id].gdrma;
        tempId[2]=families[_id].son;
        tempId[3]=families[_id].daughter;
        tempId[4]=families[_id].father;
        tempId[5]=families[_id].mother;
        
        return (tempId,families[_id].isGenesisFather,families[_id].isGenesisMother);
    }

 
    function isOwnerOf(address account, uint256[] memory _tokenIds)
        public
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (ownerOf(_tokenIds[i]) != account) return false;
        }

        return true;
    }



    function setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesReceipientAddress,
        uint96 _percentageBasisPoints
    ) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function burn(uint256 tokenId) public { 
        require(getApproved(tokenId)==msg.sender, "Not approved to burn.");
        
        _burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }  

    function batchBurn(uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            burn(_tokenIds[i]);
        }
    }



    function mint(address account,uint256[] calldata burnedFrogs,bool _isGenesisFather, bool _isGenesisMother)
        external
        onlySPIGD
    {
        //tokenIdTracker;
        uint256 tokenId = tokenIdTracker + 1;
        tokenIdTracker = tokenId;
        families[tokenIdTracker].grdpa = burnedFrogs[0];
        families[tokenIdTracker].gdrma = burnedFrogs[1];
        families[tokenIdTracker].son = burnedFrogs[2];
        families[tokenIdTracker].daughter = burnedFrogs[3];
        families[tokenIdTracker].father = burnedFrogs[4];
        families[tokenIdTracker].mother = burnedFrogs[5];
        families[tokenIdTracker].isGenesisFather = _isGenesisFather;
        families[tokenIdTracker].isGenesisMother = _isGenesisMother;
        _mintRT(account);  
        setRoyalties(tokenIdTracker,payable(owner()),750);      
    }

    function _mintRT(address to) private  {
        _safeMint(to, tokenIdTracker);

    }

    function totalSupply() public view override(ERC721A,IERC721A) returns (uint256) {
        return tokenIdTracker;
    }

/*     function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
       override 
    {
        super._beforeTokenTransfer(from, to, tokenId);
    } */
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A,IERC721A,ERC2981)
        returns (bool)
    {
        return
            
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES ||
            super.supportsInterface(interfaceId);
    }
}

