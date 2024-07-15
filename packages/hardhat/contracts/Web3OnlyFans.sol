// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Web3OnlyFans is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    address public admin;
    Counters.Counter private _tokenIdCounter;

    uint256 public constant SUBSCRIPTION_DURATION = 30 days;
    uint256 public constant REWARDS_RATE = 10; // 10 reward tokens per day

    mapping(uint256 => uint256) public subscriptionExpiry;
    mapping(address => uint256) public rewardsBalance;

    event Subscription(address indexed subscriber, uint256 indexed tokenId, uint256 timestamp);
    event RewardsClaimed(address indexed user, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        admin = msg.sender;
    }

    function subscribe() public payable nonReentrant {
        require(msg.value > 0, "Subscription fee required");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        subscriptionExpiry[tokenId] = block.timestamp + SUBSCRIPTION_DURATION;

        emit Subscription(msg.sender, tokenId, block.timestamp);
    }

    function claimRewards(uint256 tokenId) public nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of this subscription");
        require(block.timestamp <= subscriptionExpiry[tokenId], "Subscription expired");

        uint256 daysSubscribed = (block.timestamp - (subscriptionExpiry[tokenId] - SUBSCRIPTION_DURATION)) / 1 days;
        uint256 rewardsEarned = daysSubscribed * REWARDS_RATE;

        rewardsBalance[msg.sender] += rewardsEarned;

        emit RewardsClaimed(msg.sender, rewardsEarned);
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function withdraw() public onlyAdmin {
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://www.web3onlyfans.com/api/token/";
    }
}

contract LoyaltyToken is ERC20, Ownable {
    bool public transferable;
    address public loyaltyAdmin;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        loyaltyAdmin = msg.sender;
    }

    modifier onlyLoyaltyAdmin() {
        require(msg.sender == loyaltyAdmin, "Only loyalty admin can call this function");
        _;
    }

    function mint(address to, uint256 amount) public onlyLoyaltyAdmin {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function setTransferable(bool _transferable) public onlyLoyaltyAdmin {
        transferable = _transferable;
    }

    function setLoyaltyAdmin(address _loyaltyAdmin) public onlyOwner {
        loyaltyAdmin = _loyaltyAdmin;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(transferable, "Token transfers are currently disabled");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(transferable, "Token transfers are currently disabled");
        return super.transferFrom(sender, recipient, amount);
    }
}