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
 * Reward tokens must be transferred to the Vault, although the reward contract is defined on creation the rewards may
 * transferred in at any time, but that must be done before any rewards can be harvested.
 * (This model is opposed to setting an allowance for the Vault on the rewards contract).
 *
 * Reward calculation uses the share summation that is used in MasterChef V2, keeping accumulated rewards per a share
 * and deducting the ineligible portion (either due to occurring before deposit or from harvesting).
 */
contract SimpleRewardVault is ERC4626 {
    using SafeERC20 for IERC20;

    uint256 private constant REWARDS_PRECISION = 10e18;

    uint256 private _rewardTokensPerBlock;
    uint256 private _totalStaked;
    uint256 private _lastRewardedBlock;

    // Accumulated rewards per share times REWARDS_PRECISION
    uint256 private _accumulatedRewardsPerShare;

    IERC20 private _rewards;

    mapping(address => uint256) private _rewardDebt;

    event HarvestRewards(address indexed user, uint256 amount);

    constructor(ERC20 rewards_, IERC20 stakingAsset_, string memory shareName_, string memory shareSymbol_) ERC4626(stakingAsset_) ERC20(shareName_, shareSymbol_)  {
        // One whole reward token per a block split amongst all shareholders
        _rewardTokensPerBlock = 10**rewards_.decimals() * REWARDS_PRECISION;

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

    /**
     * Preview of the rewards earned if harvest in the next block e.g. current block + 1
     */
    function previewHarvestRewards(address receiver_) external view returns (uint256){
        uint totalShares = ERC20.totalSupply();

        if (ERC4626.totalAssets() > 0 && totalShares > 0) {
            uint blocksSinceLastReward = block.number - _lastRewardedBlock + 1;
            uint rewards = blocksSinceLastReward * _rewardTokensPerBlock;
            uint previewAccumulatedRewardsPerShare = _accumulatedRewardsPerShare + (rewards / totalShares);
            uint maximumRewards = (ERC20.balanceOf(receiver_) * previewAccumulatedRewardsPerShare) / REWARDS_PRECISION;
            uint rewardsToHarvest = maximumRewards - _rewardDebt[receiver_];

            return rewardsToHarvest;
        }

        return 0;
    }

    /**
     * When the vault lacks sufficient rewards harvest will revert on the attempted transfer of reward tokens.
     */
    function harvestRewards(address receiver_) public {
        updatePoolRewards();

        if (ERC4626.totalAssets() >= 0) {
            uint maximumRewards = (ERC20.balanceOf(receiver_) * _accumulatedRewardsPerShare) / REWARDS_PRECISION;
            uint rewardsToHarvest = maximumRewards - _rewardDebt[receiver_];

            if (rewardsToHarvest > 0) {
                _rewardDebt[receiver_] = maximumRewards;
                emit HarvestRewards(receiver_, rewardsToHarvest);
                SafeERC20.safeTransfer(_rewards, receiver_, rewardsToHarvest);
            }
        }
    }

    /**
     * @dev Update pool's accumulatedRewardsPerShare and lastRewardedBlock
     */
    function updatePoolRewards() private {
        uint totalShares = ERC20.totalSupply();

        if (ERC4626.totalAssets() > 0 && totalShares > 0) {
            uint256 blocksSinceLastReward = block.number - _lastRewardedBlock;
            uint256 rewards = blocksSinceLastReward * _rewardTokensPerBlock;
            _accumulatedRewardsPerShare = _accumulatedRewardsPerShare + (rewards / totalShares);
        }

        _lastRewardedBlock = block.number;
    }
}
