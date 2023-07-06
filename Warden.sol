import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Community.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Warden {
    using SafeMath for uint256;

    EpisapientToken public token;
    Community community;

    address payable owner;
    uint256 public wardenCount;
    uint256 public wardensPerCommunityRate;
    uint256 public rewardsPerBlock;
    uint256 public minimumStakeAmount;

    constructor(address _community, address _token) {
        community = Community(_community);
        owner = payable(msg.sender);
        token = EpisapientToken(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not an owner");
        _;
    }

    function changeToken(address _token) public onlyOwner {
        token = EpisapientToken(_token);
    }

    struct WardenStructure {
        address wardenAddress;
        address[] activeInCategories;
        uint256 tokensStaked;
        uint256 stakingTime;
    }

    mapping(address => WardenStructure) public wardenDetails;

    mapping(uint256 => uint256) public currentWardenCount;

    //wardens per community memebers
    mapping(uint256 => uint256) public wardensPerCommunity;

    function stakeTokens(uint256 amount)
        internal
        returns (uint256 amountStaked)
    {
        require(amount >= minimumStakeAmount, "stake amount is not sufficient");
        require(
            amount <= token.allowance(msg.sender, address(this)),
            "Less Allowance"
        );
        token.transferFrom(msg.sender, address(this), amount);
        amountStaked = amount;
    }

    function unStakeTokens(address _address) internal {
        require(
            wardenDetails[_address].tokensStaked > 0,
            "You don't have any tokens staked yet"
        );
        token.transfer(msg.sender, wardenDetails[msg.sender].tokensStaked);
    }

    // setWardensPerThousandMember(int) : this will define number of wardens a community can have per 1K members
    function changeWardensPerCommunityRate(uint256 _wardensPerCommunityRate)
        public
        onlyOwner
    {
        wardensPerCommunityRate = _wardensPerCommunityRate;
    }

    // becomeWarden(stackAmount, categoryId) - Check if user is whitelisted, Check if currentWardenCount < memberCapacity
    function becomeWarden(address communityId, uint256 amount)
        public
        returns (uint256 _wardenCount)
    {
        //updates warden
        // updateWardens(communityId);

        address[] memory totalMembers = community.communityMembersList(
            communityId
        );
        address[] memory totalWardens = community.communityWardenList(
            communityId
        );

        if (totalWardens.length > 0) {
            uint256 Res = totalMembers.length / wardensPerCommunityRate;
            require(Res > totalWardens.length, "Warden Limit Exceeded");
        }

        require(
            wardenDetails[msg.sender].tokensStaked <= 0,
            "You already are a warden!"
        );
        uint256 amountStaked = stakeTokens(amount);
        require(amountStaked > 0, "Stake Some Tokens to become a Warden");

        wardenDetails[msg.sender].wardenAddress = msg.sender;
        wardenDetails[msg.sender].activeInCategories.push(communityId);
        wardenDetails[msg.sender].tokensStaked = amountStaked;
        wardenDetails[msg.sender].stakingTime = block.timestamp;

        community.addWarden(communityId, msg.sender);

        wardenCount++;
        _wardenCount = wardenCount;
    }

    // Remove the last element.
    function removeItem(address[] storage arr, address item)
        internal
        returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == item) {
                for (uint256 j = i; j < arr.length - 1; j++) {
                    arr[j] = arr[j + 1];
                }
                arr.pop();
                return true;
            }
        }
        return false;
    }

    // removeWarden(walletAddress, categoryId) - Remove warden of particular category - Only Owner / Contract Only
    function removeWarden(address communityId, address wardenAddress)
        public
        returns (uint256 _wardenCount)
    {
        //updates warden
        // updateWardens(communityId);

        require(
            wardenDetails[wardenAddress].activeInCategories.length > 0,
            "It's Not a Warden"
        );

        unStakeTokens(wardenAddress);
        removeItem(
            wardenDetails[wardenAddress].activeInCategories,
            communityId
        );
        wardenDetails[wardenAddress].tokensStaked = 0;
        wardenDetails[wardenAddress].stakingTime = 0;

        community.removeAddress(communityId, wardenAddress);

        wardenCount--;
        _wardenCount = wardenCount;
    }

    // resign(categoryId) : will unstake the tokens and user will be removed from warden position
    function resign(address communityId) public returns (uint256 _wardenCount) {
        require(
            wardenDetails[msg.sender].activeInCategories.length > 0,
            "You're not an Warden"
        );

        //updates warden
        updateWardens(communityId);

        unStakeTokens(msg.sender);
        removeItem(wardenDetails[msg.sender].activeInCategories, communityId);
        wardenDetails[msg.sender].tokensStaked = 0;
        wardenDetails[msg.sender].stakingTime = 0;

        community.removeAddress(communityId, msg.sender);

        wardenCount--;
        _wardenCount = wardenCount;
    }

    // isWarden(walletAddress) : will check if user is warden
    function isWarden(address _address) public view returns (bool _isIt) {
        if (wardenDetails[_address].activeInCategories.length > 0) {
            _isIt = true;
        } else {
            _isIt = false;
        }
    }

    // setRewardPerBlock : Only Owner
    function setRewardPerBlock(uint256 newRewardsPerBlock) public onlyOwner {
        rewardsPerBlock = newRewardsPerBlock;
    }

    // setMiniumStakeAmount - Only Owner
    function setMiniumStakeAmount(uint256 newMinimumStakeAmount)
        public
        onlyOwner
    {
        minimumStakeAmount = newMinimumStakeAmount;
    }

    // updateWardens :  for all categories check if currentWardenCount > memberCapacity, then remove the last warden

    function updateWardens(address communityId) public returns (bool isValid) {
        address[] memory totalMembers = community.communityMembersList(
            communityId
        );
        address[] memory totalWardens = community.communityWardenList(
            communityId
        );

        uint256 wardenRate = wardensPerCommunityRate;

        if (totalWardens.length > 0) {
            // uint256 newWardenRate = totalMembers.div(totalWardens);
            uint256 newWardenRate = totalMembers.length / totalWardens.length;
            if (wardenRate > newWardenRate) {
                address[] memory arr = community.communityWardenList(communityId);
                uint256 noOfWardens = arr.length-1;
                address last = arr[noOfWardens];
                community.removeAddress(communityId, last);
                isValid = true;
            } else {
                isValid = false;
            }
        } else {
            isValid = false;
        }
        isValid;
    }

    function updateAllWardens(address communityId) public {
        address[] memory totalWardens = community.communityWardenList(communityId);

        for (uint256 i = 0; i <= totalWardens.length; i++) {
            updateWardens(communityId);
        }
    }

    function displayAll(address id)
        public
        view
        returns (address[] memory _data1, address[] memory _data2)
    {
        _data1 = community.communityWardenList(id);
        _data2 = community.communityMembersList(id);
    }
}