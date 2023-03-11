// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftMarketPlace{
       struct listing {
        address seller; 
        uint256 priceInEth; 
        uint256[]nftCostsInErc20;
        bool active; 
        bool sold; 
    }

    mapping (uint256 => listing) private _listings; // Map the NFT token IDs to their listings

    struct ListingAuction {
        address seller;
        uint256 startingPrice; 
        uint256 reservePrice;
        uint256 auctionEndTime; 
        bool active;
        bool sold; 
        address highestBidder;
        uint256 highestBid; 
    }

    mapping (uint256 => ListingAuction) private _listingsAuction; // Map the NFT token IDs to their listingsAuction

    IERC20[]tokens;// array which stores the interfaces of erc20 for payments
    uint8[]_payIds;// array which stores the payid for erc20 payments
    address public owner;

    IERC721 nftContract;
    
    constructor(address[]memory _tokenAddresses,address _nftContract){
        require(_tokenAddresses.length >0,"length of tokneAdresses should be greater then zero");
        require(_nftContract !=address(0),"invalid address");
        for(uint8 i=0;i< _tokenAddresses.length;i++){
            require(_tokenAddresses[i] != address(0),"invalid address");
            tokens.push(IERC20(_tokenAddresses[i]));
            _payIds.push(i);
        }  
        owner=msg.sender; 
        nftContract= IERC721(_nftContract);
}



    modifier onlyOwner(){
        require(msg.sender==owner,"only owner can call this function");
        _;
    }

// events start

    
    // events for listing

    event NFTListed(uint16 indexed tokenId, address indexed seller, uint256 priceInEth , IERC20[] paymentTokens , uint256 [] priceInTokens );
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    

    // events for listingAuction

    event NFTListedOnAuction(uint256 indexed tokenId, address indexed seller, uint256 startingPrice, uint256 reservePrice, uint256 auctionEndTime);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event NFTSoldOnAuction(uint256 indexed tokenId, address indexed seller, address indexed highestBidder, uint256 highestBid);
    event auctionUnSuccess(uint256 indexed tokenId, address indexed seller, uint256 reservePrice, uint256 highestBid);

// events start end


    function getPayIds()external view returns(uint8[]memory payIds){
        return _payIds;
    }

    function listNFT(uint16 tokenId, uint256 _priceInEth,uint256[]memory _pricesInErc20 ) external {
        listing storage Listing=_listings[tokenId];
        require(_pricesInErc20.length == tokens.length, "length of tokens and prices must be equal");
        require(nftContract.ownerOf(tokenId) == msg.sender, "Only the owner of the NFT can list it");
        require(!Listing.active,"this nft already listed");
        require(!_listingsAuction[tokenId].active,"this nft already listed on auction");
        require(_priceInEth>0,"price in eth must be greater then zero");
        require(nftContract.getApproved(tokenId) == address(this),"aproved the tokenId to this contract first");
        for(uint8 i=0; i<_pricesInErc20.length; i++){
            require(_pricesInErc20[i]>0,"price in erc20 must be greater then zero");
            _listings[tokenId].nftCostsInErc20.push((_pricesInErc20[i]));
        }
        nftContract.transferFrom(msg.sender,address(this),tokenId);
            Listing.seller=msg.sender;
            Listing.priceInEth=_priceInEth;
            Listing.active=true;
            Listing.sold=false;
        emit NFTListed(tokenId, msg.sender,_priceInEth, tokens , _pricesInErc20 );
    }

    function getListedNFTDetail(uint8 tokenId)public view returns(address seller,uint256 priceInEth,bool active, bool sold, uint256[] memory pricesInErc20){

        listing storage Listing=_listings[tokenId];
        return(
            Listing.seller,
            Listing.priceInEth,
            Listing.active,
            Listing.sold,
            Listing.nftCostsInErc20
        );

    }

    function delistNFT(uint256 tokenId) external {
        require(_listings[tokenId].seller == msg.sender, "Only the seller can delist the NFT");
        require(_listings[tokenId].active, "list the tokenId first");
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        _listings[tokenId].active = false;
        delete _listings[tokenId];
    }

    
    function buyListedNFT(uint16 tokenId)external payable{
        require(_listings[tokenId].active, "The NFT is not currently listed for sale");
        require(msg.value == _listings[tokenId].priceInEth, "The amount of Ether sent must be equal to the price of the NFT");
        address seller = _listings[tokenId].seller;
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        _listings[tokenId].active = false;
        payable(seller).transfer(msg.value);
        emit NFTSold(tokenId, seller, msg.sender, msg.value);

    }

    function buyNFTUsingErc20(uint16 tokenId, uint8 payId)external payable{
        listing storage Listing = _listings[tokenId];
        require(Listing.active, "The NFT is not currently listed for sale");
        require(tokens[payId].allowance(msg.sender,address(this))>=Listing.nftCostsInErc20[payId] ,"Approved the Erc20 token to nftMarketPlace first!");
        IERC20 token;
        token=tokens[payId];
        uint256 nftCostInErc20;
        nftCostInErc20 =  Listing.nftCostsInErc20[payId];
        address seller = _listings[tokenId].seller;
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        _listings[tokenId].active = false;
        _listings[tokenId].sold = true;
        tokens[payId].transferFrom(msg.sender,seller,nftCostInErc20);
        emit NFTSold(tokenId, seller, msg.sender, msg.value);
    }


    function listNFTforAution(uint256 tokenId, uint256 startingPrice, uint256 reservePrice, uint256 auctionDuration) external {
        require(nftContract.ownerOf(tokenId) == msg.sender, "Only the owner of the NFT can list it");
        require(!_listings[tokenId].active,"this nft already listed");
        require(!_listingsAuction[tokenId].active,"this nft already listed on auction");
        require(nftContract.getApproved(tokenId) == address(this),"aproved the tokenId to this contract first");
        uint256 auctionEndTime = block.timestamp + auctionDuration;
        nftContract.transferFrom(msg.sender,address(this), tokenId);
        _listingsAuction[tokenId] = ListingAuction(msg.sender, startingPrice, reservePrice, auctionEndTime, true, false, address(0), 0);
        emit NFTListedOnAuction(tokenId, msg.sender, startingPrice, reservePrice, auctionEndTime);
    }
        
        
    function getAuctionListedNFTDetail(uint8 tokenId)public view returns(address seller,uint256 startingPrice,uint256 reservePrice,uint256 auctionEndTime, bool active, bool sold, address highestBidder, uint256 highestBid){

        ListingAuction storage listingAuction=_listingsAuction[tokenId];
        return(
         listingAuction.seller,
         listingAuction.startingPrice,
         listingAuction.reservePrice,
         listingAuction.auctionEndTime,
         listingAuction.active,
         listingAuction.sold,
         listingAuction.highestBidder,
         listingAuction.highestBid
        );
    }

    function getCurrentTime()public view returns(uint256){
        return block.timestamp;
    }
    
    function delistNFTFromAuction(uint256 tokenId) external {
        require(_listingsAuction[tokenId].seller == msg.sender, "Only the seller can delist the NFT");
        require(_listingsAuction[tokenId].active, "list the tokenId first");
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        _listingsAuction[tokenId].active = false;
        delete _listingsAuction[tokenId];
    }
    
    function placeBid(uint256 tokenId) external payable {
        ListingAuction storage listingAuction = _listingsAuction[tokenId];
        require(listingAuction.active, "The NFT is not currently listed for auction");
        require(block.timestamp < listingAuction.auctionEndTime, "The auction has already ended");
        require(msg.value > listingAuction.startingPrice, "The bid must be higher than the starting Price");
        require(msg.value > listingAuction.highestBid, "The bid must be higher than the current highest bid");
        require(msg.sender != listingAuction.seller, "The seller cannot bid on their own NFT");
        if (listingAuction.highestBidder != address(0)) {
           payable( listingAuction.highestBidder).transfer(listingAuction.highestBid);
        }
        listingAuction.highestBidder = msg.sender;
        listingAuction.highestBid = msg.value;
        emit BidPlaced(tokenId, msg.sender, msg.value);
    }
    
    
    function auctionWinner(uint256 tokenId) external {
        ListingAuction storage listingAuction = _listingsAuction[tokenId];
        require(listingAuction.active, "The NFT is not currently listed for auction");
        require(block.timestamp >= listingAuction.auctionEndTime, "The auction has not yet ended");
        if (listingAuction.highestBid >= listingAuction.reservePrice) {
            address seller = listingAuction.seller;
            address winner = listingAuction.highestBidder;
            uint256 value =listingAuction.highestBid;
            nftContract.transferFrom(address(this), winner, tokenId);
            payable(seller).transfer(value);
            listingAuction.active=false;
            listingAuction.sold=true;
           emit NFTSoldOnAuction(tokenId,listingAuction.seller,listingAuction.highestBidder,listingAuction.highestBid);
            }
         else{
            payable(listingAuction.highestBidder).transfer(listingAuction.highestBid);
            address seller = listingAuction.seller;
            nftContract.transferFrom(address(this),seller, tokenId);
             emit auctionUnSuccess(tokenId,listingAuction.seller,listingAuction.reservePrice,listingAuction.highestBid);
             delete _listingsAuction[tokenId];
         }   
    }

}