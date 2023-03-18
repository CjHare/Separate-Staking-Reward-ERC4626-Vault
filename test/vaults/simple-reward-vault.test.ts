// Start - Support direct Mocha run & debug
import 'hardhat'
import '@nomiclabs/hardhat-ethers'
import {
    IERC20,
    SimpleRewardVault
} from '../../typechain-types'
import {ethers, network} from "hardhat";
import {BigNumber, utils} from "ethers";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
// End - Support direct Mocha run & debug

const EIGHTEEN_DECIMAL_PLACES = BigNumber.from(10).pow(18)
const ONE_HUNDRED_TOKENS = BigNumber.from(100).mul(EIGHTEEN_DECIMAL_PLACES)
const TWO_HUNDRED_TOKENS =BigNumber.from(200).mul(EIGHTEEN_DECIMAL_PLACES)
const ONE_MILLION_TOKENS = BigNumber.from(10e5).mul(EIGHTEEN_DECIMAL_PLACES)

// Manual mining is on; mine() must be called to produce blocks!
describe('Staking Pool Tests', () => {

        before(async () => {
            const erc20Factory = await ethers.getContractFactory('TestERC20')
            const promiseStakingContract = erc20Factory.deploy('StakingToken', 'STK', ONE_MILLION_TOKENS)
            const promisedRewardContract = erc20Factory.deploy('RewardToken', 'RTK',ONE_MILLION_TOKENS)
            await mine()

            assets = <IERC20>await promiseStakingContract
            rewards = <IERC20>await promisedRewardContract

            const signers = await ethers.getSigners()
            owner = signers[0]
            userOne = signers[1]
            userTwo = signers[2]
            userThree = signers[3]

            const factory = await ethers.getContractFactory('SimpleRewardVault')
            const promisedVaultContract = factory.deploy(rewards.address, assets.address, 'VaultToken', 'VTK')
            await mine()
            vault = <SimpleRewardVault>await promisedVaultContract

            // Give the users with their staking funds
            await
                assets.transfer(userOne.address, ONE_HUNDRED_TOKENS)
            await
                assets.transfer(userTwo.address, TWO_HUNDRED_TOKENS)
            await
                assets.transfer(userThree.address, ONE_HUNDRED_TOKENS)

            await mine()
            await mine()
        })

        it('should calculate rewards for staggered stakes and withdrawal', async () => {

            // Owner deposits 1,000,000 reward tokens (in rewards decimal)
            await rewards.transfer(vault.address, ONE_MILLION_TOKENS)

            // 1 token per a block - hardcoded in contract

            // User 1 deposits 100 token A into Vault, receiving 100 Vault tokens
            await assets.connect(userOne).approve(vault.address, ONE_HUNDRED_TOKENS)
            await vault.connect(userOne).deposit(ONE_HUNDRED_TOKENS, userOne.address)

            // User 2 deposits 200 token A into Vault, receiving 200 Vault tokens
            await assets.connect(userTwo).approve(vault.address, TWO_HUNDRED_TOKENS)
            await vault.connect(userTwo).deposit(TWO_HUNDRED_TOKENS, userTwo.address)

            // Mine the two deposits
            await mine()

            // Pass 100 blocks - 100 blocks or reward time
            await mine(100)

            // User 1 withdraws 100 tokens (burning the vault tokens) and receives 33.33 reward tokens
            await vault.connect(userOne).withdraw(ONE_HUNDRED_TOKENS, userOne.address, userOne.address)

            // User 2 keeps balance (has earned 66.66 reward tokens to date)
            //TODO previewEarnedRewards
            console.log('User2 shares: ' + await vault.previewHarvestRewards(userTwo.address))

            // Pass another 100 blocks - 100 blocks of reward time
            await mine(100)

            // User 2 keeps balance (has earned 166.66 vault tokens)
            //TODO previewEarnedRewards
            console.log('User2 shares: ' + await vault.previewHarvestRewards(userTwo.address))

            // User 3 deposits 100 token A into Vault, receiving 100 Vault tokens
            await assets.connect(userThree).approve(vault.address, ONE_HUNDRED_TOKENS)
            await vault.connect(userThree).deposit(ONE_HUNDRED_TOKENS, userThree.address)

            // Pass another 100 blocks - 99 blocks of reward time for User Three, 100 blocks for User Two
            await mine(100)

            // User 2 keeps balance (has earned 233.33 vault tokens)
            //TODO previewEarnedRewards
            console.log('User2 shares: ' + await vault.previewHarvestRewards(userTwo.address))

            // User 3 keeps balance (has earned 33.33 tokens)
            //TODO previewEarnedRewards
            console.log('User3 shares: ' + await vault.previewHarvestRewards(userThree.address))

            //TODO assets
        })

        async function mine(blocks: number = 1) {

            if (blocks == 1) {
                await network.provider.send("evm_mine")
            } else {
                // HH mine has a problem with extra zero's, they must be stripped out e.g. input of 5 breaks it "0x05"
                await network.provider.send("hardhat_mine", [utils.hexStripZeros(utils.hexlify(blocks))])
            }
        }

        let vault: SimpleRewardVault
        let assets: IERC20
        let rewards: IERC20
        let owner: SignerWithAddress
        let userOne: SignerWithAddress
        let userTwo: SignerWithAddress
        let userThree: SignerWithAddress
    }
)
