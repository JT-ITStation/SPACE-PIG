require("@nomicfoundation/hardhat-toolbox-viem");

// Ensure your configuration variables are set before executing the script
const { vars } = require("hardhat/config");

// Go to https://alchemy.com, sign up, create a new App in
// its dashboard, and add its key to the configuration variables
// const ALCHEMY_API_KEY = vars.get("ALCHEMY_API_KEY");
//const INFURA_API_KEY = vars.get("INFURA_API_KEY");
//const POLYGONSCAN_API_KEY = vars.get("POLYGONSCAN_API_KEY");



// Add your Sepolia account private key to the configuration variables
// To export your private key from Coinbase Wallet, go to
// Settings > Developer Settings > Show private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Beware: NEVER put real Ether into testing accounts
//const SEPOLIA_PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");
const ARTHERA_TESTNET_PRIVATE_KEY = vars.get("ARTHERA_TESTNET_PRIVATE_KEY")

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  settings: {
    optimizer: {
      enabled: true,
      runs: 20
    }
  },
  networks: {
/*     sepolia: {
      // url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    polygonMumbai: {
      url: `https://polygon-mumbai.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY],
    }, */
    artheraTestnet: {
      url: "https://rpc-test.arthera.net",
      accounts: [ARTHERA_TESTNET_PRIVATE_KEY]              
  }
  },
/*   etherscan: {
    // Your API key for PolygonScan
    // Obtain one at https://polygonscan.com/myapikey
    apiKey: {
      polygonMumbai: POLYGONSCAN_API_KEY
    }
  } 
  ,*/
  sourcify: {
    // Disabled by default
    // Doesn't need an API key
    enabled: true
  }
};