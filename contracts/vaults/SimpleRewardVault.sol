// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/**
 * The Vault uses three ERC20's:
 * 1) The Vaults own ERC20 is the share in the reward.
 * 2) The Reward is the ERC20 paid out for staking.
 * 2) The StakingAsset is the ERC20 the user is staking to receive their tokenized share.
 *
 * Although the Reward ERC20 is decided on creation and can be transferred in at any time, but that must be done before
 * any rewards can be harvested.
 */
contract SimpleRewardVault is ERC4626 {

    IERC20 private _rewards;

    constructor(IERC20 rewards_, IERC20 stakingAsset_, string memory shareName_, string memory shareSymbol_) ERC4626(stakingAsset_) ERC20(shareName_, shareSymbol_){
        _rewards = rewards_;
    }

    function addRewards() external {

    }

    function get() external view returns (uint256) {
        return block.number;
    }
}
