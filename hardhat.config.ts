/** @type import('hardhat/config').HardhatUserConfig */

import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'

/**
 * 0.8.18 was the latest version supported on config authoring
 *
 * https://hardhat.org/hardhat-runner/docs/reference/solidity-support
 */
export default {
  networks: {
    hardhat: {
      chainId: 33133,
      allowUnlimitedContractSize: false,
      loggingEnabled: false,
      mining: {
        auto: false,
        interval: 0
      }
    },s
    local: {
      url: 'http://localhost:8545',
      chainId: 33133,
      allowUnlimitedContractSize: false,
      loggingEnabled: true,
      mining: {
        auto: false,
        interval: 0
      }
    }
  },
  solidity: {
    compilers: [
      {
        version: '0.7.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: '0.8.18'
      }
    ]
  }
}
