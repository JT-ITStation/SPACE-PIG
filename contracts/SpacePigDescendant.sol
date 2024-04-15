// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0

pragma solidity ^0.8.24;

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
import "./SpacePigRafleTicket.sol";

contract SpacePigDescendant is 
    Ownable,   
    ERC721AQueryable,
    ERC2981,
    Pausable,    
    ReentrancyGuard,
    RoyaltiesV2Impl
{   
    uint256 private _tokenIdCounter;
    SpacePig private SPIG;
    SpacePigRafleTicket private SPIGRT;
    string public baseURI;
    uint256 public breedCoolDown = 5 minutes;
    uint256 public breedTooYoung = 10 minutes;
    uint256 public breedTooOld = 1 hours;
    uint256 public TimeRetired = 365 days;
    uint256 private breedPrice = 1000000000000000000;//0.01eth
    uint256 private test = 1;                             
    uint256 private rebirthPrice = 1000000000000;
    uint256 private speedUpPrice = 1000000000000;//perday
    uint256 dnaDigits = 3;
    uint256 dnaPower = 10 ** dnaDigits;
    struct PIG {
        uint256 lastBreed;
        uint256 birthday;
        uint256 DNA;
    }
    mapping(uint256 => PIG) private WorldPigDescendant;
    
    event breedSPIGD(uint256 _tokenid, uint256 _DNA);
    event rebirthSPIGD(uint256 _tokenid, uint256 birthday);
    event speedUpSPIGD(uint256 _tokenid, uint256 birthday);
    
    

    constructor() ERC721A("SPIGDescendant", "SPIGD") Ownable(msg.sender) {

        _setDefaultRoyalty(msg.sender, 750);
        _pause();
    }



    function setBreedPrice(uint256 _price) public onlyOwner {
        breedPrice = _price;
    }
    function setRebirthPrice(uint256 _price) public onlyOwner {
        rebirthPrice = _price;
    }
    function setSpeedUpPrice(uint256 _price) public onlyOwner {
        speedUpPrice = _price;
    }
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    function setCoolDown(uint256 _breedCoolDown ) public onlyOwner
    {
        breedCoolDown = _breedCoolDown;
    }
    function setBreedTooYoung(uint256 _breedTooYoung ) public onlyOwner
    {
        breedTooYoung = _breedTooYoung;
    }
    function setBreedTooOld(uint256 _breedTooOld) public onlyOwner
    {
        breedTooOld = _breedTooOld;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override (ERC721A,IERC721A)
        returns (string memory)
    {
        require(_tokenId < _tokenIdCounter+1 , "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function setSPIGContract(address _contract) public onlyOwner {
        SPIG = SpacePig(_contract);
    }

    function setSPIGRTContract(address _contract) public onlyOwner {
        SPIGRT = SpacePigRafleTicket(_contract);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getSPIGTotalSupply() public view returns(uint256)
    {
        return SPIG.totalSupply();
    }

     function IsSPIGOwner(uint256 id) public view returns(bool) {
         return SPIG.isOwnerOfSimple(msg.sender,id);
     }

    function getSPIG(uint256 id) public view returns(uint256,uint256,uint256) {
                
        return SPIG.getSPIG(id);
    }

    function getSPIGD(uint256 _tokenId) public view returns (uint256,uint256,uint256) {
        return(WorldPigDescendant[_tokenId].lastBreed,WorldPigDescendant[_tokenId].birthday,WorldPigDescendant[_tokenId].DNA);
    }

    function getSPIGD_DNA(uint256 id) public view returns (uint256) {
        require(id < _tokenIdCounter, "mint");
        return WorldPigDescendant[id].DNA;
    }

    function breed(uint256 tokenIdM,bool SPIGContractM,uint256 tokenIdF,bool SPIGContractF) public payable whenNotPaused() nonReentrant() {
        require(
            msg.value == breedPrice,
            "0.05 per frog."
        );
        //require(FFF,'address null');
        uint256 DNA_M;
        uint256 DNA_F;
        if(SPIGContractM){
        require(IsSPIGOwner(tokenIdM),'not Male token owner');
        uint256 _lastBreed;
        uint256 _birthday;
        uint256 _DNA;
        (_lastBreed,_birthday,_DNA) = getSPIG(tokenIdM);
        require(_lastBreed + breedCoolDown < block.timestamp,'Male breed cooldown not over');
        DNA_M = _DNA;
        }
        else
        {
        require(ownerOf(tokenIdM) ==msg.sender,'not Male token owner');
        require(WorldPigDescendant[tokenIdM].lastBreed + breedCoolDown < block.timestamp,'Male breed cooldown not over');
        require(WorldPigDescendant[tokenIdM].birthday + breedTooYoung < block.timestamp,'Too Young to breed babies');
        require(WorldPigDescendant[tokenIdM].birthday + breedTooOld > block.timestamp,'Too Old to breed babies');
        DNA_M = WorldPigDescendant[tokenIdM].DNA;
        }
        if(SPIGContractF){
        require(IsSPIGOwner(tokenIdF),'not Female token owner');        
        uint256 _lastBreedF;
        uint256 _birthdayF;
        uint256 _DNAF;
        (_lastBreedF,_birthdayF,_DNAF) = getSPIG(tokenIdF);
        require(_lastBreedF+ breedCoolDown < block.timestamp,'Female breed cooldown not over');
        DNA_F = _DNAF;
        }
        else
        {
        require(ownerOf(tokenIdF)== msg.sender,'not Female token owner');
        require(WorldPigDescendant[tokenIdF].lastBreed + breedCoolDown < block.timestamp,'Female breed cooldown not over');
        require(WorldPigDescendant[tokenIdF].birthday + breedTooYoung < block.timestamp,'Too Young to breed babies');
        require(WorldPigDescendant[tokenIdF].birthday + breedTooOld > block.timestamp,'Too Old to breed babies');
        DNA_F = WorldPigDescendant[tokenIdF].DNA;        
        }
        
        mintSPIGD(tokenIdM,DNA_M,SPIGContractM,tokenIdF,DNA_F,SPIGContractF);

    } 

    function rebirth(uint256 _tokenId) public payable whenNotPaused() nonReentrant() {
    require(ownerOf(_tokenId)== msg.sender,'not token owner');
    require(msg.value == rebirthPrice, "0.05 per frog.");
    WorldPigDescendant[_tokenId].birthday = block.timestamp;
    //emit event
    emit rebirthSPIGD(_tokenId, block.timestamp);
    }

    function speedUp(uint256 _tokenId, uint256 _days)public payable whenNotPaused() nonReentrant() {
    require(ownerOf(_tokenId)== msg.sender,'not token owner');
    require(msg.value == _days*speedUpPrice, "0.05 per frog.");
    WorldPigDescendant[_tokenId].birthday = WorldPigDescendant[_tokenId].birthday - _days;
    //emit event
    emit speedUpSPIGD(_tokenId, WorldPigDescendant[_tokenId].birthday);   
    }

    function mintSPIGD(uint256 tokenIdM,uint256 DNA_M,bool SPIGContractM,uint256 tokenIdF,uint256 DNA_F,bool SPIGContractF) private {
        uint256 tokenId = _tokenIdCounter + 1;
        _tokenIdCounter = tokenId;      
        _mint(msg.sender, _tokenIdCounter);
        uint256 tempDNA;
        uint256 temp = block.prevrandao % 5;
        if(_tokenIdCounter % 2 ==0)
        {
             
             tempDNA = DNA_F % 10**(3*temp) + DNA_M -(DNA_M % 10**(3*temp));
        }
        else
        {
             tempDNA = DNA_M % 10**(3*temp) + DNA_F -(DNA_F % 10**(3*temp));
        }
        if (SPIGContractM){
            SPIG.SetlastBreed(tokenIdM, block.timestamp);
        }
        else
        {
            WorldPigDescendant[tokenIdM].lastBreed = block.timestamp;
        }
        if (SPIGContractF){
            SPIG.SetlastBreed(tokenIdF, block.timestamp);
        }
        else
        {
            WorldPigDescendant[tokenIdF+1].lastBreed = block.timestamp;
        }
        WorldPigDescendant[_tokenIdCounter].DNA = tempDNA;
        WorldPigDescendant[_tokenIdCounter].birthday = block.timestamp;
        WorldPigDescendant[_tokenIdCounter].lastBreed = block.timestamp;
        setRoyalties(_tokenIdCounter,payable(owner()),750);
        emit breedSPIGD(_tokenIdCounter, tempDNA);
    }



   // function _mint(address to, uint256 tokenId) internal virtual override {
   //     _mint(to);
   //     emit Transfer(address(0), to, tokenId);
   // }

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
        require(ownerOf(tokenId)==msg.sender, "Not approved to burn.");
        
        _burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }  

    function batchBurn(uint256[] memory _toBurn) public {
        for (uint256 i = 0; i < _toBurn.length; i++) {
            burn(_toBurn[i]);
        }
    }

    function getRaffleTicket(uint256[] memory _tokenIds,bool _isGenesisFather, bool _isGenesisMother) public payable {
        uint256[] memory  toburn;
        uint256 size = 4;
        if (_isGenesisFather)
            {             
                require(IsSPIGOwner(_tokenIds[4]),"not token owner");
            }
        else
            {
                size = size+1;
            }
        if (_isGenesisMother)
            {    
                require(IsSPIGOwner( _tokenIds[5]),"not token owner");
            }
        else
            {
                size = size+1;              
            }
        toburn =  new uint256[] (size);
        for(uint256 i = 0; i < 4;i++)
        {
            toburn[i] = _tokenIds[i]; 
        }
        require(isOwnerOf(msg.sender, toburn),"not token owner");
        if (!_isGenesisFather)
        {
                toburn[4] = _tokenIds[4];
                if (!_isGenesisMother)
                {
                    toburn[5] = _tokenIds[5];
                }
        }
        else    
        {
        if (!_isGenesisMother)
                {
                    toburn[4] = _tokenIds[5];
                }
        }

        require(WorldPigDescendant[toburn[0]].birthday < block.timestamp - breedTooOld,"grdpa ");
        require(WorldPigDescendant[toburn[1]].birthday < block.timestamp - breedTooOld,"grand ma");
        require(WorldPigDescendant[toburn[2]].birthday > block.timestamp - breedTooYoung,"son");
        require(WorldPigDescendant[toburn[3]].birthday > block.timestamp - breedTooYoung,"daughter");
        if (!_isGenesisFather){require(((WorldPigDescendant[toburn[4]].birthday < block.timestamp - breedTooYoung)&&(WorldPigDescendant[toburn[4]].birthday > block.timestamp- breedTooOld)),"not pa");}
        if (!_isGenesisMother){require(((WorldPigDescendant[toburn[5]].birthday < block.timestamp - breedTooYoung)&&(WorldPigDescendant[toburn[5]].birthday > block.timestamp- breedTooOld)),"not ma");}
        
        batchBurn(toburn);
        mintRaffle(_tokenIds,_isGenesisFather,_isGenesisMother);
    }

    function mintRaffle(uint256[] memory _tokenIds,bool isGenesisFather, bool isGenesisMother) internal {
        SPIGRT.mint(msg.sender, _tokenIds,isGenesisFather,isGenesisMother);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    } 
    /**
     * @dev See {IERC165-supportsInterface}.
     */
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
