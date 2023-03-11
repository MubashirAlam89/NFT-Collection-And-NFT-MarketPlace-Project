// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNftCollection is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;


    
    uint16 TotalSupply=1000;

    uint256 nftMintPriceInEther= 0.0001 ether;// price for native currency

    uint8[]_payIds;// array which stores the payid for erc20 payments

    IERC20[]tokens;// array which stores the interfaces of erc20 for payments
    
    uint256[]nftMintingPricesInErc20;// price for erc20 tokens

    constructor(address[]memory _tokenAddresses,uint256[]memory _nftMintingCosts) ERC721("MyNft", "M.Nft") {
        require(_tokenAddresses.length >0,"length of tokneAdresses should be greater then zero");
        require(_tokenAddresses.length == _nftMintingCosts.length,"length of tokneAdresses and nftmintingConsts must be equal");
        for(uint8 i=0;i< _tokenAddresses.length;i++){
            require(_tokenAddresses[i] != address(0),"invalid address");
            require(_nftMintingCosts[i] >=0,"nftMintingCost should be greater then zero");
            tokens.push(IERC20(_tokenAddresses[i]));
            nftMintingPricesInErc20.push(_nftMintingCosts[i]);
            _payIds.push(i);
        }   

    }
// events start

    // Events for nftMinting
    event nftMintWithEther(address nftMinter, uint16 nftId, uint256 value);
    event nftMintWithErc20Token(address nftMinter, uint16 nftId, uint8 _tokenPayId, uint256 nftMintingCost);
    
    // event for widthdrawal
    event erc20TokenWithdraw(address from, address to, uint8 _tokenPayId , uint256 withdrawalAmount);

// events start end

 

    function _baseURI() internal pure override returns (string memory) {
        return "www.MyNftCollection.com";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function getPayIds()external view returns(uint8[]memory payIds){
        return _payIds;
    }

    function mintNftWithEth()external payable{
        require(msg.value >= nftMintPriceInEther,"Pay the required amount");
        require(_tokenIdCounter.current()<=TotalSupply,"Max Supply Reached!");
        _tokenIdCounter.increment();
        uint16 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        payable(owner()).transfer(msg.value);
        emit nftMintWithEther(msg.sender,tokenId,msg.value);
    }

    function nftMitingPricesInErc20()public view returns(uint256[]memory){
        return nftMintingPricesInErc20;
    }

    function mintNftWithErc20(uint8 _tokenPayId)external{
        require (_tokenPayId < tokens.length,"this pay id not exists");
        require(_tokenIdCounter.current()<=TotalSupply,"Max Supply Reached!");
        IERC20 token;
        uint256 nftMintingCost;
        token=tokens[_tokenPayId];
        nftMintingCost=nftMintingPricesInErc20[_tokenPayId];
        require(token.allowance(msg.sender,address(this))>=nftMintingCost,"Approve the nftMintingCost to this smart Contract first!");
        token.transferFrom(msg.sender,address(this),nftMintingCost);
        _tokenIdCounter.increment();
        uint16 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        emit nftMintWithErc20Token(msg.sender,tokenId,_tokenPayId,nftMintingCost);
    }

    function withdrawalErc20(uint8 _tokenPayId , address to )external onlyOwner{
        require (_tokenPayId < tokens.length,"this pay id not exists");
        IERC20 token=tokens[_tokenPayId];
        uint256 balance =token.balanceOf(address(this));
        require(balance > 0,"you have insufficient balance on this payid");
        token.transfer(to,balance);
        emit erc20TokenWithdraw(address(this),to,_tokenPayId,balance);
    }

  

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
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


