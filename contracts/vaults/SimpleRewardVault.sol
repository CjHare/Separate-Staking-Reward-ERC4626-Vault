// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
    using SafeERC20 for IERC20;

    uint256 private constant REWARDS_PRECISION = 1e12; // A big number to perform mul and div operations

    uint256 private _rewardTokensPerBlock;
    uint256 private _totalStaked;
    uint256 private _lastRewardedBlock;
    uint256 private _accumulatedRewardsPerShare; // Accumulated rewards per share times REWARDS_PRECISION

    IERC20 private _rewards;

    mapping(address => uint256) private _rewardDebt;

    event HarvestRewards(address indexed user, uint256 amount);

    constructor(IERC20 rewards_, IERC20 stakingAsset_, string memory shareName_, string memory shareSymbol_) ERC4626(stakingAsset_) ERC20(shareName_, shareSymbol_)  {
        _rewards = rewards_;
    }

    function deposit(uint256 assets_, address receiver_) public virtual override returns (uint256) {
        harvestRewards(receiver_);

        uint amount = ERC20.balanceOf(receiver_) + ERC4626.convertToShares(assets_);
        _rewardDebt[receiver_] = amount * _accumulatedRewardsPerShare / REWARDS_PRECISION;

        return ERC4626.deposit(assets_, receiver_);
    }

    function withdraw(
        uint256 assets_,
        address receiver_,
        address owner_
    ) public virtual override returns (uint256) {
        harvestRewards(receiver_);

        return ERC4626.withdraw(assets_, receiver_, owner_);
    }


    function harvestRewards(address receiver_) public {
        updatePoolRewards();

        if (ERC4626.totalAssets() >= 0) {
            uint maximumRewards = ERC20.balanceOf(receiver_) * _accumulatedRewardsPerShare / REWARDS_PRECISION;
            uint rewardsToHarvest = maximumRewards - _rewardDebt[receiver_];
            if (rewardsToHarvest > 0) {
                _rewardDebt[receiver_] = maximumRewards;
                emit HarvestRewards(receiver_, rewardsToHarvest);
                SafeERC20.safeTransferFrom(_rewards, address(this), receiver_, rewardsToHarvest);
            }
        }
    }

    /**
     * @dev Update pool's accumulatedRewardsPerShare and lastRewardedBlock
     */
    function updatePoolRewards() private {
        if (ERC4626.totalAssets() == 0) {
            _lastRewardedBlock = block.number;
            return;
        }
        uint256 blocksSinceLastReward = block.number - _lastRewardedBlock;
        uint256 rewards = blocksSinceLastReward * _rewardTokensPerBlock;
        _accumulatedRewardsPerShare = _accumulatedRewardsPerShare + (rewards * REWARDS_PRECISION / ERC20.balanceOf(address(this)));
        _lastRewardedBlock = block.number;
    }

    /*
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        revert("mint is disabled");
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        revert("redeem is disabled");
    }
    */
}
