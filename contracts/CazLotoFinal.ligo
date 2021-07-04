type player is record
  addr : address;
  value : nat;
end;

type storage is record
  gameState : bool;
  gameCreator : address;
  minAmount : tez;
  players : set(player);
  bannedUsers : set(address);
end;

type betValue is record
  value : nat;
end;

type startLotoParam is record
  result : nat;
end;

type banParam is record
  player : address;
end;

type entryAction is
  | Fund of unit
  | Bet of betValue
  | StartLoto of startLotoParam
  | BanUser of banParam
  | UnbanUser of banParam

function ligoAssert(const p : bool; const s: string) : unit is
  block { if p then skip else failwith(s) }
  with unit

function banUser (var self : storage ; const user : address) : storage is
  block {
    ligoAssert(Tezos.sender = self.gameCreator, "Tezos.sender = self.gameCreator");
    if not (self.bannedUsers contains user)
        then self.bannedUsers := Set.add(user, self.bannedUsers);
    else failwith ("Warning: This user is already banned.");
  } with self

function unbanUser (var self : storage ; const user : address) : storage is
  block {
    ligoAssert(Tezos.sender = self.gameCreator, "Tezos.sender = self.gameCreator");
    if self.bannedUsers contains user
        then self.bannedUsers := Set.remove(user, self.bannedUsers);
    else failwith ("Warning: This user has not been banned.");
  } with self

function bet (var self : storage; const num : nat) : (storage) is block {
    ligoAssert(Tezos.amount >= self.minAmount, "Tezos.amount = self.minAmount");
    ligoAssert(((num > 0n) and (num <= 1000n)), "(value > 0n) and (value <= 1000n)");
    ligoAssert(not(self.bannedUsers contains Tezos.sender), "You are banned from the Casino, sir");
    const currentBetter : player = record[addr=Tezos.sender;value=num];
    self.players := Set.add(currentBetter, self.players);
} with (self);

function fund(const self : storage) : (storage) is block {
    skip
} with (self);

function startLoto(var self : storage; const result : nat) : (list(operation) * storage) is
  block {
    ligoAssert(Tezos.sender = self.gameCreator, "Tezos.sender = self.gameCreator");
    ligoAssert((Set.size(self.players) > 0n), "size(self.players) > 0n");
    var winners : set (address) := set [];
    var ops : list(operation) := nil;
    for el in set self.players block {
      if(el.value = result) then block {
        const winner_update : set(address) =  Set.add(el.addr, winners);
        winners := winner_update;
      } else skip;
    };
    for el in set self.players block {
      if(el.value = result) then block {
        const receiver : contract (unit) =
          case (Tezos.get_contract_opt(el.addr): option(contract(unit))) of
            Some (contract) -> contract
          | None -> (failwith ("Not a contract") : (contract(unit)))
          end;
        const op0 : operation = transaction(unit, (Tezos.balance/(Set.size(winners))), receiver);
        const final_ops : list(operation) = op0 # ops;
        ops := final_ops; 
      } else skip;
    };
    self.players := (Set.empty : set(player));
} with (ops, self);

function main (const action : entryAction; const self : storage) : (list(operation) * storage) is
  block {
    skip
  } with case action of
  | Fund -> ((nil : list(operation)), fund(self))
  | Bet(params) -> ((nil : list(operation)), bet(self, params.value))
  | StartLoto(params) -> startLoto(self, params.result)
  | BanUser(params) -> ((nil : list(operation)), banUser(self, params.player))
  | UnbanUser(params) -> ((nil : list(operation)), unbanUser(self, params.player))
  end