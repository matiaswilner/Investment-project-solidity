require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

require("@nomiclabs/hardhat-ethers");

const ALCHEMY_API_KEY = "-LI-bHpSVfiJf_fGUEyxGTXdgeZ2ww6E";

const ROPSTEN_PRIVATE_KEY = "6bded2cc1f91168cc6298a0fcf4e1405d56c70a4893daf2f99ab9173f8c5b844";

/**
* @type import('hardhat/config').HardhatUserConfig
*/
module.exports = {
  solidity: "0.8.4",
  networks: {
    ropsten: {
      url: `https://eth-ropsten.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${ROPSTEN_PRIVATE_KEY}`]
    }
  }
};