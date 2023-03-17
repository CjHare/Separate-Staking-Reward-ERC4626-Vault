// Start - Support direct Mocha run & debug
import 'hardhat'
import '@nomiclabs/hardhat-ethers'
import {
    IERC20,
    SimpleRewardVault
} from '../../typechain-types'
import {ethers, network} from "hardhat";
import {utils} from "ethers";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
// End - Support direct Mocha run & debug

// Manual mining is on; mine() must be called to produce blocks!
describe('Staking Pool Tests', () => {

        before(async () => {
            const erc20Factory = await ethers.getContractFactory('TestERC20')
            const promiseStakingContract = erc20Factory.deploy('StakingToken', 'STK')
            const promisedRewardContract = erc20Factory.deploy('RewardToken', 'RTK')
            await mine()

            stakingToken = <IERC20>await promiseStakingContract
            rewardToken = <IERC20>await promisedRewardContract

            const signers = await ethers.getSigners()
            owner = signers[0]
            userOne = signers[1]
            userTwo = signers[2]
            userThree = signers[3]

            const factory = await ethers.getContractFactory('SimpleRewardVault')
            const promisedVaultContract = factory.deploy(rewardToken.address, stakingToken.address, 'VaultToken', 'VTK')
            await mine()
            vault = <SimpleRewardVault>await promisedVaultContract

            // Give the users with their staking funds
            await
                stakingToken.transfer(userOne.address, 100)
            await
                stakingToken.transfer(userTwo.address, 200)
            await
                stakingToken.transfer(userThree.address, 100)

            await mine()
            await mine()
        })

        it('should calculate rewards for staggered stakes and withdrawal', async () => {

            // Owner deposits 1,000,000 reward tokens
//TODO add reward method
//    vault.connect(owner)

            // 1 token per a block

            // User 1 deposits 100 token A into Vault, receiving 100 Vault tokens
            await stakingToken.connect(userOne).approve(vault.address,100)
           await vault.connect(userOne).deposit(100, userOne.address)

            // User 2 deposits 200 token A into Vault, receiving 200 Vault tokens
            await stakingToken.connect(userTwo).approve(vault.address,200)
        await vault.connect(userTwo).deposit(200, userTwo.address)

            // Pass 100 blocks
            await mine(100)


            console.log(await vault.asset())
            console.log(await vault.totalAssets())
            console.log(await vault.totalSupply())

            console.log(await stakingToken.balanceOf(userOne.address))
            console.log(await stakingToken.balanceOf(userTwo.address))


            console.log(await vault.balanceOf(userOne.address))
            console.log(await vault.balanceOf(userTwo.address))

            console.log(await rewardToken.balanceOf(userOne.address))
            console.log(await ethers.provider.getBlockNumber())


            // User 1 withdraws 100 tokens (burning the vault tokens) and receives 33.33 reward tokens

            // User 2 keeps balance (has earned 66.66 reward tokens to date)

            // Pass another 100 blocks

            // User 2 keeps balance (has earned 166.66 vault tokens)

            // User 3 deposits 100 token A into Vault, receiving 100 Vault tokens

            // Pass another 100 blocks

            // User 2 keeps balance (has earned 233.33 vault tokens)

            // User 3 keeps balance (has earned 33.33 tokens)
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
        let stakingToken: IERC20
        let rewardToken: IERC20
        let owner: SignerWithAddress
        let userOne: SignerWithAddress
        let userTwo: SignerWithAddress
        let userThree: SignerWithAddress
    }
)
