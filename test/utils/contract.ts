import {ethers} from 'hardhat'
import {Contract} from 'ethers'
import {expect} from 'chai'
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers'

export async function deploy(
    contractName: string,
    ...args: Array<unknown>
): Promise<Contract> {
    const erc20Factory = await ethers.getContractFactory(contractName)
    return erc20Factory.deploy(...args)
}

export async function signer(index: number): Promise<SignerWithAddress> {
    const signers = await ethers.getSigners()
    expect(signers.length).is.greaterThan(index)
    return signers[index]
}
