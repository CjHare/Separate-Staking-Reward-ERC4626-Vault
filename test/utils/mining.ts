import {network} from 'hardhat'
import {utils} from 'ethers'

/**
 * Advances forward the chain.
 *
 * Depending on the input, the corresponding events related to mining may or may not be generated.
 *
 * @param blocks amount of blocks to advance the chain bu, must be greater than zero, defaults to one.
 */
export async function mine(blocks = 1) {
    if (blocks === 1) {
        await network.provider.send('evm_mine')
    } else {
        // HH mine has a problem with extra zero's, they must be stripped out e.g. input of 5 breaks it "0x05"
        await network.provider.send('hardhat_mine', [
            utils.hexStripZeros(utils.hexlify(blocks))
        ])
    }
}
