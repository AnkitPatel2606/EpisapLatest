//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EpisapientToken.sol";
import "./Community.sol";

contract NFTMarketPlace is ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter public _itemIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _collectionIds;
    address payable Owner;
    EpisapientToken token;
    Community community;
    address TokenContract;
    address Treasury;

    constructor(
        address _tokenaddress,
        address _treasury,
        address _community
    ) {
        Owner = payable(msg.sender);
        token = EpisapientToken(_tokenaddress);
        Treasury = _treasury;
        TokenContract = _tokenaddress;
        community = Community(_community);
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        address[] parents;
        bool sold;
        bool firstTimeSell;
    }

    struct collectionItem {
        uint256 collectionId;
        string collectionName;
        MarketItem[] marketData;
        uint256 collectionPrice;
        bool active;
        bool sold;
    }

    mapping(uint256 => MarketItem) public idMarketItem;
    mapping(uint256 => collectionItem) public collection;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        address[] parents,
        bool sold,
        bool firstTimeSell
    );

    modifier onlyOwner() {
        require(msg.sender == Owner, "only owner can change price");
        _;
    }

    function transferOwnership(address _newowner) public onlyOwner {
        require(Owner == msg.sender, "you are not a owner");
        Owner = payable(_newowner);
    }

    function changeTokenAddress(address _tokenaddress) public onlyOwner {
        token = EpisapientToken(_tokenaddress);
        TokenContract = _tokenaddress;
    }

    /// @notice function to create market item
    function createMarketItem(
        uint256 tokenid,
        uint256 price,
        address[] memory _members,
        address nftContract,
        address from,
        uint256 collection_Id,
        bool mintedType
    ) public nonReentrant {
        if (mintedType == false) {
            require(price > 0, "Price must be above zero");

            _itemIds.increment();
            uint256 itemid = _itemIds.current();
            idMarketItem[itemid] = MarketItem(
                itemid,
                nftContract,
                tokenid,
                from,
                address(this),
                price,
                _members,
                false,
                false
            );

            IERC721(nftContract).transferFrom(from, address(this), tokenid);

            emit MarketItemCreated(
                itemid,
                nftContract,
                tokenid,
                from,
                address(this),
                price,
                _members,
                false,
                false
            );
        } else {
            require(price > 0, "Price must be above zero");

            uint256 _price = price;
            address[] memory member = _members;
            uint256 totalprice = 0;

            _itemIds.increment();
            uint256 itemid = _itemIds.current();
            idMarketItem[itemid] = MarketItem(
                itemid,
                nftContract,
                tokenid,
                from,
                address(0),
                price,
                _members,
                false,
                false
            );

            MarketItem memory newItem = MarketItem(
                itemid,
                nftContract,
                tokenid,
                from,
                address(this),
                price,
                _members,
                false,
                false
            );

            IERC721(nftContract).transferFrom(from, address(this), tokenid);

            collection[collection_Id].marketData.push(newItem);
            collection[collection_Id].active = true;
            collection[collection_Id].sold = false;
            totalprice = collection[collection_Id].collectionPrice + _price;

            emit MarketItemCreated(
                itemid,
                nftContract,
                tokenid,
                from,
                address(this),
                _price,
                member,
                false,
                false
            );

            collection[collection_Id].collectionPrice = totalprice;
        }
    }

    /// @notice function to create a sale
    function createMarketSale(uint256 itemId) public nonReentrant {
        address nftContract = idMarketItem[itemId].nftContract;
        uint256 _price = idMarketItem[itemId].price;
        uint256 tokenId = idMarketItem[itemId].tokenId;

        if (idMarketItem[itemId].firstTimeSell == false) {
            address[] memory _members = idMarketItem[itemId].parents;
            uint256 _creatorPrice = (_price.mul(97.5 * 10).div(100)).div(10);
            IERC20(TokenContract).transferFrom(
                msg.sender,
                _members[0],
                _creatorPrice
            );
            uint256 _treasuryPrice = (_price.mul(2.5 * 10).div(100)).div(10);
            IERC20(TokenContract).transferFrom(
                msg.sender,
                Treasury,
                _treasuryPrice
            );
            uint256 _contributorPrice = _price.div(10);
            uint256[] memory _divided = new uint256[](9);

            _divided[0] = 15;
            _divided[1] = 12;
            _divided[2] = 10;
            _divided[3] = 10;
            _divided[4] = 10;
            _divided[5] = 8;
            _divided[6] = 6;
            _divided[7] = 4;
            _divided[8] = 25;
            if (_members.length >= 9) {
                uint256 _newMemberLength = _members.length - 7;
                for (uint256 i = 0; i < 8; i++) {
                    uint256 contributorDividedPrice = (
                        _contributorPrice.mul(_divided[i])
                    ).div(100);
                    IERC20(TokenContract).transferFrom(
                        msg.sender,
                        _members[i],
                        contributorDividedPrice
                    );
                }

                uint256 AllcontributorPrice = (
                    (_contributorPrice.mul(_divided[8]).div(100))
                ).div(_newMemberLength);

                for (uint256 i = 7; i < _members.length; i++) {
                    IERC20(TokenContract).transferFrom(
                        msg.sender,
                        _members[i],
                        AllcontributorPrice
                    );
                }
            } else if (_members.length <= 8) {
                uint256 sum;
                for (uint256 i = 0; i < _members.length; i++) {
                    uint256 contributorDivPrice = (
                        _contributorPrice.mul(_divided[i])
                    ).div(100);
                    IERC20(TokenContract).transferFrom(
                        msg.sender,
                        _members[i],
                        contributorDivPrice
                    );
                    sum = sum + contributorDivPrice;
                }

                uint256 contributorPrice = _contributorPrice - sum;
                uint256 allContributorPrice = contributorPrice /
                    _members.length;

                for (uint256 i = 0; i < _members.length; i++) {
                    IERC20(TokenContract).transferFrom(
                        msg.sender,
                        _members[i],
                        allContributorPrice
                    );
                }
            }
            IERC721(nftContract).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            idMarketItem[itemId].owner = msg.sender;
            idMarketItem[itemId].sold = true;
            idMarketItem[itemId].firstTimeSell = true;

            _itemsSold.increment();
        } else {
            uint256 _creatorPrice = (_price.mul(97.5 * 10).div(100)).div(10);
            IERC20(TokenContract).transferFrom(
                msg.sender,
                idMarketItem[itemId].seller,
                _creatorPrice
            );
            uint256 _treasuryPrice = (_price.mul(2.5 * 10).div(100)).div(10);
            IERC20(TokenContract).transferFrom(
                msg.sender,
                Treasury,
                _treasuryPrice
            );
            IERC721(nftContract).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            idMarketItem[itemId].owner = msg.sender;
            idMarketItem[itemId].sold = true;
            idMarketItem[itemId].firstTimeSell = true;
            _itemsSold.increment();
        }
    }

    //Function for resele token

    function reSellToken(uint256 itemId, uint256 price) public {
        require(
            idMarketItem[itemId].owner == msg.sender,
            "only item owner this operation"
        );
        address nftContract = idMarketItem[itemId].nftContract;
        uint256 tokenid = idMarketItem[itemId].tokenId;
        idMarketItem[itemId].sold = false;
        idMarketItem[itemId].price = price;
        idMarketItem[itemId].seller = msg.sender;
        idMarketItem[itemId].owner = address(this);
        _itemsSold.decrement();
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenid);
    }

    /// @notice total number of items unsold on our platform
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        //loop through all items ever created
        for (uint256 i = 0; i < itemCount; i++) {
            if (idMarketItem[i + 1].owner == address(this)) {
                //yes, this item has never been sold
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items; //return array of all unsold items
    }

    /// @notice fetch list of NFTS owned/bought by this user
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        //get total number of items ever created
        uint256 totalItemCount = _itemIds.current();

        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            //get only the items that this user has bought/is the owner
            if (idMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1; //total length
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /// @notice fetch list of NFTS owned/bought by this user
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        //get total number of items ever created
        uint256 totalItemCount = _itemIds.current();

        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            //get only the items that this user has bought/is the owner
            if (idMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1; //total length
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getcollectionId() public view returns (uint256) {
        uint256 collectionId = _collectionIds.current();
        return collectionId;
    }

    function setcollectionId(
        uint256 tokenid,
        uint256 price,
        address[] memory _members,
        address nftContract,
        address from,
        string memory name
    ) public {
        _collectionIds.increment();
        uint256 collectionId = _collectionIds.current();
        require(price > 0, "Price must be above zero");

        uint256 _price = price;
        address[] memory member = _members;

        _itemIds.increment();
        uint256 itemid = _itemIds.current();
        idMarketItem[itemid] = MarketItem(
            itemid,
            nftContract,
            tokenid,
            from,
            address(0),
            price,
            _members,
            false,
            false
        );

        MarketItem memory newItem = MarketItem(
            itemid,
            nftContract,
            tokenid,
            from,
            address(this),
            price,
            _members,
            false,
            false
        );
        IERC721(nftContract).transferFrom(from, address(this), tokenid);
        collection[collectionId].marketData.push(newItem);
        collection[collectionId].active = true;
        collection[collectionId].sold = false;
        collection[collectionId].collectionId = collectionId;
        collection[collectionId].collectionName = name;
        collection[collectionId].collectionPrice = price;

        emit MarketItemCreated(
            itemid,
            nftContract,
            tokenid,
            from,
            address(this),
            _price,
            member,
            false,
            false
        );
    }

    function fetchTotalCollection() public view returns (uint256[] memory) {
        uint256 collectionids = _collectionIds.current();
        uint256 soldCollection = 0;

        for (uint256 i = 0; i < collectionids; i++) {
            if (collection[i + 1].sold == true) {
                soldCollection++;
            }
        }
        uint256 activeCollection = collectionids - soldCollection;
        uint256[] memory acctiveCollectionIds = new uint256[](activeCollection);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < collectionids; i++) {
            if (collection[i + 1].sold == false) {
                acctiveCollectionIds[currentIndex] = collection[i + 1]
                    .collectionId;
            }
        }

        return acctiveCollectionIds;
    }

    function fetchColloctionName(uint256 id)
        public
        view
        returns (string memory)
    {
        string memory name = collection[id].collectionName;
        return name;
    }

    function fetchCollectionItems(uint256 id)
        public
        view
        returns (MarketItem[] memory)
    {
        MarketItem[] memory items = collection[id].marketData;
        return items;
    }

    function buyCollection(uint256 id) public {
        collectionItem storage collectiondata = collection[id];
        require(collectiondata.active == true, "this Collection is Not Active");
        require(
            collectiondata.sold == false,
            "this Collection is sold already"
        );

        uint256 itemlength = collectiondata.marketData.length;

        for (uint256 i = 0; i < itemlength; i++) {
            uint256 itemid = collectiondata.marketData[i].itemId;
            createMarketSale(itemid);
        }
        collectiondata.active = false;
        collectiondata.sold = true;
    }
}

