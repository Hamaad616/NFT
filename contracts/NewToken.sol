//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./token/ERC721/extensions/ERC721Enumerable.sol";
import "./access/Ownable.sol";
import "./@rarible/royalties/contracts/Impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
// import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./@rarible/royalties/contracts/LibRoyalties2981.sol";

contract NewToken is ERC721Enumerable, Ownable, RoyaltiesV2Impl{
    using Strings for uint256;
    string public baseURI;
    uint public txFeeAmount;
    string public baseExtension = ".json";
    uint256 public cost = 0.05 ether;
    uint256 public presaleCost = 0.03 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 10;
    bool public paused = false;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public presaleWallets;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor() ERC721("NewToken","NTKN") {
        setBaseURI("ipfs://QmesKpcJXY6WSbaSr4Pq9DQeMb4UonyrMzenb4nJ8dfoDV/");
        mint(msg.sender, 10);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }



    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            if (whitelisted[msg.sender] != true) {
                if (presaleWallets[msg.sender] != true) {
                    //general public
                    require(msg.value >= cost * _mintAmount);
                } else {
                    //presale
                    require(msg.value >= presaleCost * _mintAmount);
                }
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function addPresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = true;
    }

    function add100PresaleUsers(address[100] memory _users) public onlyOwner {
        for (uint256 i = 0; i < 2; i++) {
            presaleWallets[_users[i]] = true;
        }
    }

    function removePresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = false;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasesPoints) public onlyOwner{
            LibPart.Part[] memory _royalties = new LibPart.Part[](1);
            _royalties[0].value = _percentageBasesPoints;
            _royalties[0].account = _royaltiesRecipientAddress;
            _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool){
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES){
            return true;
        }

        if(interfaceId == _INTERFACE_ID_ERC2981){
            return true;
        }

        return super.supportsInterface(interfaceId);
    }


}
