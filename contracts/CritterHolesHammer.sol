// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CritterHolesHammer is ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    
    uint256 public constant BASE_ID = 0;
    uint256 public constant LEVEL_1_ID = 1;
    uint256 public constant LEVEL_2_ID = 2;

    mapping(uint256 => uint256) public levelPrices;
    
    mapping(address => bool) private _hasMintedBase;

    event PriceUpdated(uint256 indexed levelId, uint256 newPrice);
    event NFTUpgraded(address indexed user, uint256 oldLevel, uint256 newLevel);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _initialOwner) public initializer {
        __ERC1155_init("https://critterholes.xyz/metadata/{id}.json");
        __Ownable_init(_initialOwner);
        __UUPSUpgradeable_init();

        levelPrices[BASE_ID] = 1 ether;
        levelPrices[LEVEL_1_ID] = 10 ether;
        levelPrices[LEVEL_2_ID] = 20 ether;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function name() public pure returns (string memory) {
        return "Critter Holes Hammer";
    }

    function symbol() public pure returns (string memory) {
        return "HAMMER";
    }

    function mintBase() external payable {
        require(!_hasMintedBase[msg.sender], "HAMMER: You have already minted the base NFT.");
        require(msg.value >= levelPrices[BASE_ID], "HAMMER: Incorrect ETH amount sent for mint.");

        _hasMintedBase[msg.sender] = true;
        _mint(msg.sender, BASE_ID, 1, "");
    }

    function upgradeNFT(uint256 _newLevelId) external payable {
        uint256 _currentLevelId;

        if (balanceOf(msg.sender, LEVEL_1_ID) == 1) {
            _currentLevelId = LEVEL_1_ID;
        } else if (balanceOf(msg.sender, BASE_ID) == 1) {
            _currentLevelId = BASE_ID;
        } else {
            revert("HAMMER: You do not own an NFT to upgrade.");
        }

        require(_newLevelId == _currentLevelId + 1, "HAMMER: Invalid upgrade path or target level.");
        require(_newLevelId <= LEVEL_2_ID, "HAMMER: No further upgrades available.");
        require(msg.value >= levelPrices[_newLevelId], "HAMMER: Incorrect ETH amount sent for upgrade.");

        _burn(msg.sender, _currentLevelId, 1);

        _mint(msg.sender, _newLevelId, 1, "");
        
        emit NFTUpgraded(msg.sender, _currentLevelId, _newLevelId);
    }

    function updatePrice(uint256 _levelId, uint256 _newPrice) external onlyOwner {
        require(_levelId <= LEVEL_2_ID, "HAMMER: Invalid level ID.");
        levelPrices[_levelId] = _newPrice;
        emit PriceUpdated(_levelId, _newPrice);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "HAMMER: No balance to withdraw.");

        (bool success, ) = owner().call{value: balance}("");
        require(success, "HAMMER: Withdrawal failed.");
    }

    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "HAMMER: Insufficient token balance.");
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function hasMintedBase(address user) external view returns (bool) {
        return _hasMintedBase[user];
    }
}