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

import "./rarible/impl/RoyaltiesV2Impl.sol";
import "./rarible/LibPart.sol";
import "./rarible/LibRoyaltiesV2.sol";

import "./Whitelist.sol";
import "./SpacePigDescendant.sol";

contract SpacePig is Ownable, ERC721A,ERC721AQueryable, ERC2981,ReentrancyGuard,RoyaltiesV2Impl {
    uint256 private tokenIdTracker;
    string public baseURI;
    bool private paused = true;
    bool private presaleIsActive = false;

    uint256 private constant MAX_SPIG = 1000;
    uint256 private constant MAX_PURCHASE = 10;
    uint256 private constant MAX_NUM_OF_PRESALE_SPIG = 100;
    uint256 private constant MINT_PRICE = 1000000000000;// 0.05 ether;
    uint256 private  BREED_COOLDOWN = 5 minutes;
    uint256 private  BREED_TOO_YOUNG = 10 minutes;
    uint256 private  BREED_TOO_OLD = 1 hours;
    uint256 private TEAM_RESERVE = 20;
    
    WhitelistContract private myWL;


    struct Pig {
        uint256 lastBreed;
        uint256 birthday;
        uint256 DNA;
    }

    mapping(uint256 => Pig) private worldPig;
    SpacePigDescendant private SPIGD;

    constructor() ERC721A("SpacePig", "SPIG") Ownable(msg.sender){
        _setDefaultRoyalty(msg.sender, 750);
        myWL = new WhitelistContract();
        
    }



    modifier onlySPIGD() {
        require(msg.sender == address(SPIGD), "403");
        _;
    }

    function SetlastBreed(uint256 id,uint256 _lastBreed) external onlySPIGD {
        require(worldPig[id].lastBreed+ BREED_COOLDOWN < _lastBreed,"worng breed date");
        worldPig[id].lastBreed = _lastBreed;
    }

    function setSPIGD(SpacePigDescendant _SPIGD) public onlyOwner {
        SPIGD = _SPIGD;
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
        require(ownerOf(_tokenId) != address(0), "Token not exist");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function getSPIG(uint256 _tokenId) public view returns (uint256,uint256,uint256) {
        return(worldPig[_tokenId].lastBreed,worldPig[_tokenId].birthday,worldPig[_tokenId].DNA);
    }


    function mint(uint256 amount) public payable nonReentrant{
        require(!paused || presaleIsActive, "Minting is paused");
        require(amount > 0 && amount <= MAX_PURCHASE, "Invalid amount");
        require(msg.value == MINT_PRICE * amount, "Incorrect ether value sent");
        require(tokenIdTracker + amount <= MAX_SPIG, "Exceeds maximum supply");

        for (uint256 i = 0; i < amount; i++) {
            _mintPig();
        }
    }

    function _mintPig() private {
        uint256 tokenId = tokenIdTracker + 1;
        tokenIdTracker = tokenId;
        _safeMint(msg.sender, tokenId);

        uint256 randomDNA = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp,
                    tokenId
                )
            )
        );
//insérer à tokenID-1 pour etre aligner avec owner ???  => voir en détail les fonctions du 721A pour lister les token d'un wallet
        worldPig[tokenId] = Pig({
            lastBreed: block.timestamp,
            birthday: block.timestamp,
            DNA: randomDNA
        });
    }




    function presaleMint(uint256 numOfPigs) public payable nonReentrant {
        // Presale minting function
        require(presaleIsActive, "Presale is not active");
        require(myWL.addressIsPresaleApproved(msg.sender),"not wl");        
        require(tokenIdTracker + numOfPigs < MAX_NUM_OF_PRESALE_SPIG, "max presale");
        require(myWL.getReservedPresaleQuantity(msg.sender)+ 1 > numOfPigs,"qty");
        require(MINT_PRICE * numOfPigs == msg.value,"not correct");
        myWL.refreshQuantity(msg.sender,numOfPigs);
        for (uint256 i=0; i < numOfPigs; i++) {            
            _mintPig();
        }
    }

    function reservePigs(uint256 amount) public onlyOwner {
        // Reserve pigs for the team
        require(amount < TEAM_RESERVE, "amount");        
        require(tokenIdTracker + amount < MAX_SPIG, "tags");
        TEAM_RESERVE = TEAM_RESERVE - amount;
        for (uint256 i=0; i < amount; i++) {           
            _mintPig();
        }
    }

    function getSPIG_DNA(uint256 id) public view returns (uint256) {
        require(id < tokenIdTracker+1, "mint");
        return worldPig[id].DNA;
    }

    function flipPause() public virtual onlyOwner {
        paused = !paused;
    }

    function addToWhitelist(address  _adr,uint256 Qty) public virtual onlyOwner {
        myWL.addToWhitelist(_adr, Qty);
    }
    
    function refreshQuantity(address _address, uint256 usedQty) public virtual onlyOwner {
        myWL.refreshQuantity(_address, usedQty);
    }  
    
    function getReservedPresaleQuantity(address _address)
        public
        view
        returns (uint256)
    {
        return myWL.getReservedPresaleQuantity(_address);
    }

    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function totalSupply() public view override (ERC721A,IERC721A) returns (uint256) {
        return tokenIdTracker;
    }    

    function walletOfOwner(address _owner_loc)
        public
        view
        returns (uint256[] memory)
    {
/*         
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        } */
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


    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (ownerOf(_tokenIds[i]) != account) return false;
        }

        return true;
    }

    function isOwnerOfSimple(address account, uint256 _tokenIds)
        public
        view
        returns (bool)
    {
        return ownerOf(_tokenIds) == account;
    } 

    function withdraw() external onlyOwner nonReentrant{
        payable(owner()).transfer(address(this).balance);
    }




    // Implement ERC2981 royalty function
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
    
    
    

    // Implement ERC165 supportsInterface function
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A,IERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES ||
            super.supportsInterface(interfaceId);
    }
}
