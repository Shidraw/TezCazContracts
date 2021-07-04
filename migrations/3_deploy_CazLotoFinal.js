const { MichelsonMap } = require("@taquito/taquito");

const CazLotoFinal = artifacts.require("CazLotoFinal");

const store = {
  gameState: false,
  gameCreator: "tz1TdevbKxkZDgFrFuTjzy9uvMmkatjeCsDD",
  // modifier le minAmount pour que ça soit 1tez (Bignumber 1 000 000)
  minAmount: 1,
  players: [],
  bannedUsers: [],
}

module.exports = async(deployer) => {
  deployer.deploy(CazLotoFinal, store);
  //const RouletteInstance = await Roulette.deployed();
  //await RouletteInstance.initialize([["unit"]]);
};
