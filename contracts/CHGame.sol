// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CHGame is Ownable, ReentrancyGuard {
    struct PlayerInfo {
        uint256 dailyClaimsUsed;
        uint256 periodStartTimestamp;
    }

    struct RewardTokenInfo {
        IERC20 token;
        uint256 maxClaim;
    }

    IERC20 public immutable CHP;
    address public immutable Super;

    RewardTokenInfo public rewardToken2;
    RewardTokenInfo public rewardToken3;

    uint256 public dailyClaimLimit;
    uint256 public maxClaimCHP;
    uint256 public constant COOLDOWN_PERIOD = 12 hours;

    mapping(address => PlayerInfo) public players;
    mapping(uint256 => bool) public usedNonces;

    event Claimed(address indexed user, address indexed token, uint256 amount);
    event DailyLimitUpdated(uint256 newLimit);
    event RewardTokenUpdated(uint8 indexed tokenSlot, address indexed tokenAddress, uint256 newMaxClaim);

    constructor(
        address initialOwner,
        address _CHP,
        address _token2,
        address _token3,
        address _Super
    ) Ownable(initialOwner) {
        CHP = IERC20(_CHP);
        Super = _Super;
        dailyClaimLimit = 4;
        maxClaimCHP = 300; 
        
        
        rewardToken2 = RewardTokenInfo({
            token: IERC20(_token2),
            maxClaim: 25 * 1e16
        });
        
        rewardToken3 = RewardTokenInfo({
            token: IERC20(_token3),
            maxClaim: 5 * 1e18
        });
    }

    function claim(bytes memory databytes, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        PlayerInfo storage player = players[msg.sender];

        if (block.timestamp >= player.periodStartTimestamp + COOLDOWN_PERIOD) {
            player.dailyClaimsUsed = 0;
            player.periodStartTimestamp = block.timestamp;
        }

        require(player.dailyClaimsUsed < dailyClaimLimit, "CHGame: Daily claim limit reached");

        (
            address recipient,
            uint256 amountCHP,
            address rewardTokenAddress,
            uint256 rewardTokenAmount,
            uint256 deadline,
            uint256 nonce
        ) = abi.decode(databytes, (address, uint256, address, uint256, uint256, uint256));

        require(recipient == msg.sender, "CHGame: Invalid recipient");
        require(block.timestamp <= deadline, "CHGame: Signature expired");
        require(!usedNonces[nonce], "CHGame: Nonce already used");
        require(amountCHP <= maxClaimCHP, "CHGame: CHP amount exceeds max limit");

        if (rewardTokenAddress == address(rewardToken2.token)) {
            require(rewardTokenAmount <= rewardToken2.maxClaim, "CHGame: Token2 amount exceeds max limit");
        } else if (rewardTokenAddress == address(rewardToken3.token)) {
            require(rewardTokenAmount <= rewardToken3.maxClaim, "CHGame: Token3 amount exceeds max limit");
        } else {
            revert("CHGame: Invalid reward token");
        }

        bytes32 messageHash = keccak256(databytes);
        address recoveredSigner = ecrecover(messageHash, v, r, s);
        require(recoveredSigner == Super, "CHGame: Invalid signature");

        player.dailyClaimsUsed++;
        usedNonces[nonce] = true;

        CHP.transfer(recipient, amountCHP);
        emit Claimed(recipient, address(CHP), amountCHP);

        IERC20(rewardTokenAddress).transfer(recipient, rewardTokenAmount);
        emit Claimed(recipient, rewardTokenAddress, rewardTokenAmount);
    }

    function UDaily(uint256 _newDailyLimit) external onlyOwner {
        dailyClaimLimit = _newDailyLimit;
        emit DailyLimitUpdated(_newDailyLimit);
    }

    function UToken(uint8 _tokenSlot, address _newTokenAddress, uint256 _newMaxClaim) external onlyOwner {
        require(_tokenSlot == 2 || _tokenSlot == 3, "CHGame: Invalid token slot");
        if (_tokenSlot == 2) {
            rewardToken2 = RewardTokenInfo({
                token: IERC20(_newTokenAddress),
                maxClaim: _newMaxClaim
            });
        } else {
            rewardToken3 = RewardTokenInfo({
                token: IERC20(_newTokenAddress),
                maxClaim: _newMaxClaim
            });
        }
        emit RewardTokenUpdated(_tokenSlot, _newTokenAddress, _newMaxClaim);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(owner(), _amount);
    }
}