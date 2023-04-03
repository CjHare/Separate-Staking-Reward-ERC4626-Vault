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

    uint256 private constant _REWARDS_PRECISION = 10e18;

    IERC20 private immutable _rewards;
    uint256 private immutable _rewardTokensPerBlock;
    uint256 private _lastRewardedBlock;

    // Accumulated rewards per share times REWARDS_PRECISION
    uint256 private _accumulatedRewardsPerShare;

    mapping(address => uint256) private _rewardDebt;

    event HarvestRewards(
        address indexed receiver,
        address indexed owner,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed receiver,
        address indexed owner,
        uint256 shares
    );

    constructor(
        ERC20 rewards_,
        IERC20 stakingAsset_,
        string memory shareName_,
        string memory shareSymbol_
    ) ERC4626(stakingAsset_) ERC20(shareName_, shareSymbol_) {
        // One whole reward token per a block split amongst all shareholders
        _rewardTokensPerBlock = 10 ** rewards_.decimals() * _REWARDS_PRECISION;

        _rewards = rewards_;
    }

    /**
     *  Full withdrawal by the user, abandoning all and any owed rewards. EMERGENCY ONLY.
     *
     * @param receiver recipient of the assets being withdrawn.
     * @return assets amount of the assets that were transferred to the receiver.
     */
    function emergencyWithdraw(
        address receiver
    ) external returns (uint256 assets) {
        _rewardDebt[msg.sender] = 0;
        uint shares = ERC4626.maxRedeem(msg.sender);

        uint supplyAfterWithdrawal = _totalShares() - shares;
        _updatePoolRewards(supplyAfterWithdrawal);

        emit EmergencyWithdraw(receiver, msg.sender, shares);
        return ERC4626.redeem(shares, receiver, msg.sender);
    }

    /**
     * Preview of the rewards earned if harvest in the next block e.g. current block + 1
     */
    function previewHarvestRewards(
        address receiver_
    ) external view returns (uint256) {
        uint totalShares = ERC20.totalSupply();

        if (ERC4626.totalAssets() > 0 && totalShares > 0) {
            uint blocksSinceLastReward = block.number - _lastRewardedBlock;
            uint rewards = blocksSinceLastReward * _rewardTokensPerBlock;
            uint previewAccumulatedRewardsPerShare = _accumulatedRewardsPerShare +
                    (rewards / totalShares);
            uint maximumRewards = (ERC20.balanceOf(receiver_) *
                previewAccumulatedRewardsPerShare) / _REWARDS_PRECISION;
            uint rewardsToHarvest = maximumRewards - _rewardDebt[receiver_];

            return rewardsToHarvest;
        }

        return 0;
    }

    function deposit(
        uint256 assets_,
        address receiver_
    ) public virtual override returns (uint256) {
        harvestRewards(receiver_);

        uint amount = ERC20.balanceOf(receiver_) +
            ERC4626.convertToShares(assets_);
        _rewardDebt[receiver_] =
            (amount * _accumulatedRewardsPerShare) /
            _REWARDS_PRECISION;

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
     * When the vault lacks sufficient rewards harvest will revert on the attempted transfer of reward tokens.
     */
    function harvestRewards(address receiver_) public {
        _updatePoolRewards(_totalShares());

        if (ERC4626.totalAssets() > 0) {
            uint maximumRewards = (ERC20.balanceOf(receiver_) *
                _accumulatedRewardsPerShare) / _REWARDS_PRECISION;
            uint rewardsToHarvest = maximumRewards - _rewardDebt[receiver_];

            if (rewardsToHarvest > 0) {
                _rewardDebt[receiver_] = maximumRewards;
                emit HarvestRewards(receiver_, msg.sender, rewardsToHarvest);
                SafeERC20.safeTransfer(_rewards, receiver_, rewardsToHarvest);
            }
        }
    }

    /**
     * @dev Update pool's accumulatedRewardsPerShare and lastRewardedBlock
     */
    function _updatePoolRewards(uint totalShares) private {
        if (ERC4626.totalAssets() > 0 && totalShares > 0) {
            uint256 blocksSinceLastReward = block.number - _lastRewardedBlock;
            uint256 rewards = blocksSinceLastReward * _rewardTokensPerBlock;
            _accumulatedRewardsPerShare =
                _accumulatedRewardsPerShare +
                (rewards / totalShares);
        }

        _lastRewardedBlock = block.number;
    }

    /**
     * @dev Helps with code readability, to avoid confusion over which suppyl is being referred to.
     * ERC20.totalSupply() is the total amount of current shares.
     * ERC4626.totalSupply() is the total amount of assets.
     */
    function _totalShares() private view returns (uint256) {
        return ERC20.totalSupply();
    }
}
