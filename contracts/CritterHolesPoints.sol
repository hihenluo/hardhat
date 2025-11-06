// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CritterHolesPoints is ERC20, ERC20Burnable, Ownable, AccessControl {
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    uint256 public constant MAX_SUPPLY = 10_000_000;

    bool public transfersEnabled = true;

    event TransfersStatusChanged(bool enabled);

    constructor(address initialOwner) ERC20("Critter Holes Points", "CHP") Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(TRANSFER_ROLE, initialOwner);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "CHP: Max supply exceeded");
        _mint(to, amount);
    }

    function setTransfersEnabled(bool _enabled) public onlyOwner {
        transfersEnabled = _enabled;
        emit TransfersStatusChanged(_enabled);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && to != address(0)) {
            require(transfersEnabled || hasRole(TRANSFER_ROLE, _msgSender()), "CHP: Transfers are currently disabled");
        }
        super._update(from, to, value);
    }
}