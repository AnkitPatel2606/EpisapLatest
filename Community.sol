// Specify the version of Solidity to use
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the Ownable contract from the OpenZeppelin library
import "@openzeppelin/contracts/access/Ownable.sol";

// Import the EpisapientToken contract
import "./EpisapientToken.sol";

// Define the Community contract which inherits from the Ownable contract
contract Community is Ownable {
    // Declare a variable to store the EpisapientToken contract
    EpisapientToken token;

    // Declare a counter for the community category IDs
    uint256 public categoryIdCounter = 0;

    // Declare a counter for the number of communities added
    uint8 public addcommunityCounter = 0;

    // Declare a counter for the membership IDs
    uint256 public membershipCounter = 0;

    // Define a struct for storing information about a community
    struct Communities {
        address ContractAddress;
        uint256 categoryId;
        uint256 id;
        address[] membersAddress;
        address[] wardenAddress;
    }

    // Define a struct for storing information about a category
    struct Category {
        string name;
        uint256 id;
    }

    // Define a struct for storing information about a member
    struct Member {
        address communityAddress;
        address walletAddress;
        uint256 id;
    }

    // Declare a mapping to store details about each category
    mapping(uint256 => Category) public categoryDetails;

    // Declare a mapping to store details about each community
    mapping(address => Communities) public communityDetails;

    // Declare a mapping to store details about each member
    mapping(address => Member) public memberDetails;

    // Declare an array to store the addresses of all communities
    address[] public communityList;

    // Declare an array to store the IDs of all categories
    uint256[] public categoryList;

    // Declare an array to store the addresses of all members
    address[] public membersList;

    // Define a constructor function for the Community contract
    constructor(address tokenAddress) {
        // Set the token variable to the EpisapientToken contract
        token = EpisapientToken(tokenAddress);
    }

    // Define a modifier to allow only the owner or a warden of a community to call a function
    modifier onlyOwnerAndWarden(
        address contractAddress,
        address wardenAddress
    ) {
        require(
            msg.sender == owner() || isWarden(contractAddress, msg.sender),
            "only owner and wadern can call"
        );
        _;
    }

    // Define a function to add a new community
    function addCommunity(address ContractAddress, uint256 categoryId) public {
        // Check if the specified category ID exists
        require(categoryId < categoryIdCounter, "Category not Exist");
        // Declare empty arrays for members and wardens
        address[] memory arr;
        address[] memory arr1;
        // Create a new Communities struct with the specified values
        Communities memory newCommunities = Communities(
            ContractAddress,
            categoryId,
            addcommunityCounter,
            arr,
            arr1
        );
        // Add the new community to the communityDetails mapping
        communityDetails[ContractAddress] = newCommunities;
        // Add the new community to the communityList array
        communityList.push(ContractAddress);
        // Increment the addcommunityCounter
        addcommunityCounter++;
    }

    // Adds a new category with the provided name
    function addCategorie(string memory name) public onlyOwner {
        // Create a new Category object with the provided name and categoryIdCounter
        Category memory newCategory = Category(name, categoryIdCounter);
        // Add the new category object to the categoryDetails mapping with categoryIdCounter as the key
        categoryDetails[categoryIdCounter] = newCategory;
        // Add the categoryIdCounter to the end of the categoryList array
        categoryList.push(categoryIdCounter);
        // Increment the categoryIdCounter for the next category to be added
        categoryIdCounter++;
    }

    // Removes a category with the provided categoryId
    function removeCategoryByID(uint256 categoryId) public onlyOwner {
        // Check if the categoryId exists in the categoryList array
        require(
            categoryId <= categoryList.length,
            "This Category does not Exist"
        );
        // Overwrite the category to be removed with the last category in the list
        categoryList[categoryId] = categoryList[categoryList.length - 1];
        // Remove the last element in the categoryList array
        categoryList.pop();
    }

    // Returns an array of all Category objects in the categoryList array
    function getCategoryList() public view returns (Category[] memory) {
        // Create a new array of Category objects with a length of categoryList
        Category[] memory result = new Category[](categoryList.length);
        // Iterate over the categoryList array and add the corresponding Category object from categoryDetails to the result array
        for (uint256 i = 0; i < categoryList.length; i++) {
            result[i] = categoryDetails[categoryList[i]];
        }
        // Return the result array of Category objects
        return result;
    }

    // Adds a new member to a community
    function addMember(address communityAddress, address walletAddress)
        public
        payable
    {
        // Get the community details from the communityDetails mapping
        Communities storage community = communityDetails[communityAddress];
        // Check if the community exists
        require(community.ContractAddress != address(0), "Community not found");
        // Check if the member already exists

        if (memberDetails[walletAddress].communityAddress == address(0)) {
            uint256 platformFee = token.getPlatformFee("Register");
            address platformAddress = token.getPlatformAddress();
            // Transfer the platform fee to the platform address
            if (platformFee > 0) {
                token.TokenTransfer(platformAddress, platformFee);
            }
            // Add the walletAddress to the membersAddress array in the community
            community.membersAddress.push(walletAddress);
            // Create a new Member object with the communityAddress, walletAddress, and membershipCounter
            Member memory newmember = Member(
                communityAddress,
                walletAddress,
                membershipCounter
            );
            // Add the new Member object to the memberDetails mapping with the walletAddress as the key
            memberDetails[walletAddress] = newmember;
            // Add the walletAddress to the end of the membersList array
            membersList.push(walletAddress);
            // Increment the membershipCounter for the next member to be added
            membershipCounter++;
        }
        // Get the platform fee and address for the registration
    }

    // This function returns an array of all members in the contract
    function getMemberList() public view returns (Member[] memory) {
        // Create a new array to store member details
        Member[] memory result = new Member[](membersList.length);

        // Loop through each member and add their details to the result array
        for (uint256 i = 0; i < membersList.length; i++) {
            result[i] = memberDetails[membersList[i]];
        }

        // Return the result array
        return result;
    }

    // This function returns platform fee and balance details for a given account
    function read(address acc)
        public
        view
        returns (
            uint256 _platformFee,
            address _PlatformFeeAddress,
            uint256 balance
        )
    {
        // Get the platform fee and platform address from the token contract
        _platformFee = token.getPlatformFee("Register");
        _PlatformFeeAddress = token.getPlatformAddress();

        // Get the account balance from the token contract
        balance = token.balanceOf(acc);
    }

    // This function sends tokens to a given address
    function sendfees(address to, uint256 amount) public {
        // Call the token contract to transfer tokens to the given address
        token.TokenTransfer(to, amount);
    }

    // This function removes a member from a given community contract by their wallet address
    function removeMemberByWalletAddress(
        address contractAddress,
        address walletAddress
    ) public onlyOwnerAndWarden(contractAddress, walletAddress) {
        // Get the array of members of the community from the contract storage
        address[] storage arr = communityDetails[contractAddress]
            .membersAddress;
        // Loop through the array to find the member with the given wallet address
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == walletAddress) {
                // If found, shift all elements to the left to remove the member from the array
                for (uint256 j = i; j < arr.length - 1; j++) {
                    arr[j] = arr[j + 1];
                }
                // Remove the last element of the array (which is now a duplicate) and update the storage
                arr.pop();
                // Return true to indicate that the member was successfully removed
            }
        }
        // Return false to indicate that the member was not found
    }

    // This function adds a warden to a given community contract
    function addWarden(address _contract, address _address) public {
        // Get the array of wardens of the community from the contract storage
        address[] storage arr = communityDetails[_contract].wardenAddress;
        // Add the new warden to the array and update the storage
        arr.push(_address);
    }

    // This function removes a warden from a community
    function removeWarden(address _contract, address item)
        public
        returns (bool)
    {
        address[] storage arr = communityDetails[_contract].wardenAddress; // get the array of wardens of the community
        for (uint256 i = 0; i < arr.length; i++) {
            // loop through the array to find the warden
            if (arr[i] == item) {
                // if the warden is found
                for (uint256 j = i; j < arr.length - 1; j++) {
                    // shift the remaining elements to the left
                    arr[j] = arr[j + 1];
                }
                arr.pop(); // remove the last element of the array
                return true; // indicate that the warden was successfully removed
            }
        }
        return false;
    }

    // This function returns a list of all the members' addresses of a particular community specified by '_contractaddress'.
    function communityMembersList(address _contractaddress)
        public
        view
        returns (address[] memory)
    {
        return communityDetails[_contractaddress].membersAddress;
    }

    // This function returns a list of all the wardens' addresses of a particular community specified by '_contractaddress'.
    function communityWardenList(address _contractaddress)
        public
        view
        returns (address[] memory)
    {
        return communityDetails[_contractaddress].wardenAddress;
    }

    // This function checks whether the provided _wardenAddress is a warden of the community with the given _contractaddress or not.
    // It returns a boolean value: true if the address is a warden, false otherwise.
    function isWarden(address _contractaddress, address _wardenAddress)
        public
        view
        returns (bool)
    {
        // get the array of wardens of the community
        address[] storage arr = communityDetails[_contractaddress]
            .wardenAddress;
        // loop through the array to check if the given _wardenAddress is present or not
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == _wardenAddress) {
                return true; // if the address is found, return true
            }
        }
        return false; // if the address is not found, return false
    }
}
