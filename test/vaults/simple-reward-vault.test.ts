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
import {fail} from "assert";
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
        const promisedVaultContract = factory.deploy(stakingToken.address, rewardToken.address, 'VaultToken', 'VTK')
        await mine()
        vault = <SimpleRewardVault>await promisedVaultContract

        // Give the users with their staking funds
        stakingToken.transfer(userOne.address, 100).catch(reason => fail('Failed to transfer userOne their staking tokens', reason))
        stakingToken.transfer(userTwo.address, 200).catch(reason => fail('Failed to transfer userTwo their staking tokens', reason))
        stakingToken.transfer(userThree.address, 100).catch(reason => fail('Failed to transfer userThree their staking tokens', reason))
        await mine()
    })

it('should calculate rewards for staggered stakes and withdrawal', async()=>{

    // Owner deposits 1,000,000 reward tokens
//TODO add reward method
//    vault.connect(owner)

    // 1 token per a block

    // User 1 deposits 100 token A into Vault, receiving 100 Vault tokens

    // User 2 deposits 200 token A into Vault, receiving 200 Vault tokens

    // Pass 100 blocks

    // User 1 withdraws 100 tokens (burning the vault tokens) and receives 33.33 reward tokens

    // User 2 keeps balance (has earned 66.66 reward tokens to date)

    // Pass another 100 blocks

    // User 2 keeps balance (has earned 166.66 vault tokens)

    // User 3 deposits 100 token A into Vault, receiving 100 Vault tokens

    // Pass another 100 blocks

    // User 2 keeps balance (has earned 233.33 vault tokens)

    // User 3 keeps balance (has earned 33.33 tokens)
})


    it('TODO name me!', async () => {

        //TODO code
        vault.get().then(n => {
            console.log('made it ' + n)
        })

        await mine()

    })

    async function mine(blocks: number = 1) {
        // HH mine has a problem with extra zero's, they must be stripped out e.g. input of 5 breaks it "0x05"
        await network.provider.send("hardhat_mine", [utils.hexStripZeros(utils.hexlify(blocks))]);
    }

    let vault: SimpleRewardVault
    let stakingToken: IERC20
    let rewardToken: IERC20
    let owner: SignerWithAddress
    let userOne: SignerWithAddress
    let userTwo: SignerWithAddress
    let userThree: SignerWithAddress
})
