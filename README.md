# TezCazContracts
Smart Contracts for Casino games on Tezos

<!-- ABOUT THE PROJECT -->
## About The Project
This repo is the result of a truffle architecture, you will need Truffle if you want to recompile or deploy these contracts.

Different contracts:
* A Loto contract that simulates a Loto game with a number range of 1 to 1000.
* A Roulette contract that simulates a Roulette game, where you can either bet on a color (red or black) or a number from 0 to 36.

### Built With

Major frameworks or libraries used in the project.
* [PascalLigo](https://ligolang.org/)
* [Truffle Tezos](https://www.trufflesuite.com/docs/tezos/truffle/quickstart)

### Prerequisites

As explained before, you will need Truffle Tezos to recompile or deploy.

### Installation

1. Follow the installation of the Truffle suite Tezos
2. Clone the repo
   ```sh
   git clone https://github.com/Shidraw/TezCazContracts/
   ```
4. Compile & Deploy contracts
   ```sh
   truffle deploy --network edo2net --reset
   ```

