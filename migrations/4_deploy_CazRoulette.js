const { MichelsonMap } = require("@taquito/taquito");

const CazRoulette = artifacts.require("CazRoulette");

const store = {
  gameState: false,
  gameCreator: "tz1TdevbKxkZDgFrFuTjzy9uvMmkatjeCsDD",
  betAmount : 0,
  requiredBalance : 0,
  winnings : new MichelsonMap(),
  payouts : new MichelsonMap(),
  numberRange : new MichelsonMap(),
  bets : new MichelsonMap(),
  bannedUsers: [],
}

module.exports = async(deployer) => {
  deployer.deploy(CazRoulette, store);
  //const RouletteInstance = await Roulette.deployed();
  //await RouletteInstance.initialize([["unit"]]);
};
