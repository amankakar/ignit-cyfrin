/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-ethers")
require("@openzeppelin/hardhat-upgrades")
require("@nomicfoundation/hardhat-chai-matchers");
require('dotenv').config();

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.5.17"
      },
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  etherscan: {
    apiKey: {
      snowtrace: "snowtrace", // apiKey is not required, just set a placeholder
    },
    // customChains: [
    //   {
    //     network: "snowtrace",
    //     chainId: 43113,
    //     urls: {
    //       apiURL: "https://api.routescan.io/v2/network/testnet/evm/43113/etherscan",
    //       browserURL: "https://avalanche.testnet.localhost:8080"
    //     }
    //   }
    // ]
  },
  networks: {
    sepolia: {
      url: `https://shape-sepolia.g.alchemy.com/v2/${process.env.SEPOLIA_API_KEY}`,
      accounts: [process.env.SEPOLIA_PRIVATE_KEY , "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6","0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e" , "0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0" , "0x689af8efa8c651a91ad287602527f3af2fe9f6501a7ac4b061667b5a93e037fd" , "0xc526ee95bf44d8fc405a158bb884d9d1238d99f0612e9f33d006bb0789009aaa" , "0x47c99abed3324a2707c28affff1267e45918ec8c3f20b8aa892e8b065d2942dd"]
    },
    binance: {
      url: 'https://data-seed-prebsc-1-s1.bnbchain.org:8545',
      accounts: [process.env.BINANCE_PRIVATE_KEY , "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6" , "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6" , "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6" , "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6" , "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6" , "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6"]
    }
    // ,
    // snowtrace: {
    //   url: 'https://api.avax-test.network/ext/bc/C/rpc',
    //   accounts: [process.env.FUJI_PRIVATE_KEY_DEPLOYER, process.env.FUJI_PRIVATE_KEY_BENQI_SUPER_ADMIN, process.env.FUJI_PRIVATE_KEY_BENQI_ADMIN, process.env.FUJI_PRIVATE_KEY_ZEEVE_SUPER_ADMIN, process.env.FUJI_PRIVATE_KEY_ZEEVE_ADMIN, process.env.FUJI_PRIVATE_KEY_OTHER]
    // }
  }
};
