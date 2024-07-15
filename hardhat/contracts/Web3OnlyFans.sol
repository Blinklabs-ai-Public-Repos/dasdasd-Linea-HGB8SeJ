// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Web3OnlyFans is ERC721Enumerable, Ownable {
    // Variables
    address public admin;
    uint256 private _tokenCounter;

    // Events
    event Subscription(address indexed subscriber, uint256 indexed tokenId, uint256 timestamp);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    // Constructor
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        admin = msg.sender;
    }

    // Subscribe to creator
    function subscribe() public payable {
        require(msg.value > 0, "Subscription fee required");

        _tokenCounter++;
        _mint(msg.sender, _tokenCounter);

        emit Subscription(msg.sender, _tokenCounter, block.timestamp);
    }

    // Set admin
    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    // Withdraw contract balance
    function withdraw() public onlyAdmin {
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
    }

    // Contract metadata URI
    function _baseURI() internal pure override returns (string memory) {
        return "https://www.web3onlyfans.com/api/token/";
    }
}