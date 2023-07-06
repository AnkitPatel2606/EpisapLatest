// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract EpisapientToken is ERC20, Ownable {
    using SafeMath for uint256;
    ERC20 public usdc;
    uint256 public tokenPrice;
    address payable public PlatformFeeAddress;
    uint256 public feeAmount;
    uint256 public tokenInOneUSD = 10000;
    IERC20 public USDTtoken;
    uint256 baseDecimals;
    address public recipient;

    address dataOracle;
    struct PlatformFee {
        string feeType;
        uint256 amount;
    }

    struct Tokenomics {
        string Type;
        uint256 Percentage;
    }

    mapping(string => PlatformFee) public platformfee;
    mapping(string => Tokenomics) public tokenomics;

    constructor(
        string memory name,
        string memory symbol,
        address _recipient,
        address _USDTtoken
    ) ERC20(name, symbol) {
        _mint(msg.sender, 4200000000 * (10**18));
        tokenPrice = 10**16;
        dataOracle = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
        USDTtoken = IERC20(_USDTtoken);
        baseDecimals = (10**18);
        recipient = _recipient;
    }

    function setPeggedTokenAddress(address _usdcaddress) public onlyOwner {
        usdc = ERC20(_usdcaddress);
    }

    function calculateUsdcperTokenAmount(uint256 usdcAmount)
        public
        view
        returns (uint256)
    {
        uint256 tokenAmount = (usdcAmount * tokenPrice) / 10**18;
        return tokenAmount;
    }

    function calculateTokenPerUsdcAmount(uint256 tokenAmount)
        public
        view
        returns (uint256)
    {
        uint256 usdcAmount = (tokenAmount * 10**18) / tokenPrice;
        return usdcAmount;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setTokenInOneUSD(uint256 rate) external onlyOwner {
        tokenInOneUSD = rate;
    }

    function getmaticLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = Aggregator(dataOracle).latestRoundData();
        price = (price * (10**10));
        return uint256(price);
    }

    // This function is used to set the address where platform fees will be sent to
    function setPlatformFeeAddress(address payable _PlatformFeeAddress)
        public
        onlyOwner
    {
        PlatformFeeAddress = _PlatformFeeAddress;
    }

    // This function is used to set the platform fees
    function setPlatformFee(string memory feeType, uint256 amount)
        public
        onlyOwner
    {
        require(amount >= 0, "Fee amount cannot be negative");
        PlatformFee memory newFee = PlatformFee(feeType, amount);
        platformfee[feeType] = newFee;
    }

    // This function is used to set the tokenomics (i.e., the distribution of tokens)
    function setTokenomics(string memory Type, uint256 percentage)
        public
        onlyOwner
    {
        require(percentage <= 100, "Percentage is less than 100");
        uint256 Amount = (totalSupply() * percentage) / 100;
        Tokenomics memory newTokenomics = Tokenomics(Type, Amount);
        tokenomics[Type] = newTokenomics;
    }

    function getPlatformFee(string memory feeType)
        public
        view
        returns (uint256)
    {
        PlatformFee memory fee = platformfee[feeType];
        return fee.amount;
    }

    function getPlatformAddress() public view returns (address) {
        return PlatformFeeAddress;
    }

    function TokenTransfer(address to, uint256 amount) public {
        transfer(to, amount);
    }

    function burnToken(address to, uint256 amount) public {
        _burn(to, amount);
    }

    function buyToken() public payable {
        uint256 tokenAmount = getTokensPerEth(msg.value);

        _transfer(recipient, msg.sender, tokenAmount);

        payable(recipient).transfer(msg.value);
    }

    function setTokenAllowance(uint256 amount) public {
        require(
            USDTtoken.approve(address(this), amount),
            "Failed to approve allowance"
        );
    }

    function buyTokenwithUSDT(uint256 uamount) public {
        setTokenAllowance(uamount);
        uint256 maticPrice = getmaticLatestPrice();

        uint256 maticEquiv = uamount.mul(10**18).div(maticPrice);

        uint256 tokenAmount = getTokensPerEth(maticEquiv);

        require(
            USDTtoken.transferFrom(msg.sender, recipient, uamount),
            "usdt not transfer"
        );

        _transfer(recipient, msg.sender, tokenAmount);
    }

    function getTokensPerEth(uint256 amount_) public view returns (uint256) {
        uint256 tokenAmount = amount_
        .mul(tokenInOneUSD.mul(getmaticLatestPrice()).div(baseDecimals.mul(100)))
        .div(10**18);
    
    return tokenAmount.mul(10**18);
    }
}

