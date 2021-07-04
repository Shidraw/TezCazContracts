    type roulette_Bet is record
    player : address;
    betType : nat;
    number : nat;
    end;

    type storage is record
    gameState : bool;
    gameCreator : address;
    betAmount : tez;
    requiredBalance : tez;
    winnings : map(address, tez);
    payouts : map(nat, nat);
    numberRange : map(nat, nat);
    bets : map(nat, roulette_Bet);
    bannedUsers : set(address);
    end;

    type betParams is record
    number : nat;
    betType : nat;
    end;

    type startRouletteParam is record
    result : nat;
    end;

    type banParam is record
    player : address;
    end;

    type entryAction is
    | InitGame of unit
    | Fund of unit
    | StartRoulette of startRouletteParam
    | Bet of betParams
    | BanUser of banParam
    | UnbanUser of banParam

    const roulette_Bet_0 : roulette_Bet = record [ 
    player = ("tz1TdevbKxkZDgFrFuTjzy9uvMmkatjeCsDD" : address);
    betType = 0n;
    number = 0n ];

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

    function init (var self : storage) : (storage) is block {
        ligoAssert(self.gameState = False, "gameCreator already exist");
        self.gameState := True;
        self.gameCreator := Tezos.sender;
        self.requiredBalance := 0tez;
        self.payouts := map
        0n -> 2n;
        1n -> 20n;
        end;
        self.numberRange := map
        0n -> 1n;
        1n -> 36n;
        end;
        self.betAmount := 1tez;
    } with (self);

    function bet (var self : storage; const number : nat; const betType : nat) : (storage) is block {
        ligoAssert(Tezos.amount = self.betAmount, "Tezos.amount = self.betAmount");
        ligoAssert(((betType >= 0n) and (betType <= 5n)), "(betType >= 0n) and (betType <= 5n)");
        ligoAssert((number >= 0n) and (number <= (case self.numberRange[betType] of | None -> 0n | Some(x) -> x end)), "Out of range");
        const payoutForThisBet : tez = ((case self.payouts[betType] of | None -> 0n | Some(x) -> x end) * Tezos.amount);
        const provisionalBalance : tez = (self.requiredBalance + payoutForThisBet);
        ligoAssert((provisionalBalance < Tezos.balance), "provisionalBalance < Tezos.balance");
        self.requiredBalance := (self.requiredBalance + payoutForThisBet);
        self.bets[size(self.bets)] := record [ betType = betType;
        player = Tezos.sender;
        number = number ];
    } with (self);

    function fund(const self : storage) : (storage) is block {
        skip
    } with (self);

    function cashOut (var self : storage) : (list(operation) * storage) is
    block {
        const player : address = Tezos.sender;
        const res_amount : tez = (case self.winnings[player] of | None -> 0tez | Some(x) -> x end);
        assert((res_amount > 0tez));
        assert((res_amount <= Tezos.balance));
        self.winnings[player] := 0tez;
        const op0 : operation = transaction((unit), res_amount, (get_contract(player) : contract(unit)));
    } with (list [op0], self);


    function startRoulette(var self : storage; const result : nat) : (list(operation) * storage) is
    block {
        ligoAssert(Tezos.sender = self.gameCreator, "Tezos.sender = self.gameCreator");
        ligoAssert((size(self.bets) > 0n), "size(self.bets) > 0n");
        for i := 0 to int (size(self.bets)) block {
        var won : bool := False;
        const b : roulette_Bet = (case self.bets[abs(i)] of | None -> roulette_Bet_0 | Some(x) -> x end);
        if (result = 0n) then block {
            won := ((b.betType = 1n) and (b.number = 0n));
        } else block {
            if (b.betType = 1n) then block {
            won := (b.number = result);
            } else block {
            if (b.betType = 0n) then block {
                if (b.number = 0n) then block {
                won := ((result mod 2n) = 0n);
                } else block {
                skip
                };
                if (b.number = 1n) then block {
                won := ((result mod 2n) = 1n);
                } else block {
                skip
                };
            } else block {
                skip
            };
            };
            }; 
        if (won) then block {
            self.winnings[b.player] := ((case self.winnings[b.player] of | None -> 0tez | Some(x) -> x end) + (self.betAmount * (case self.payouts[b.betType] of | None -> 0n | Some(x) -> x end)));
        } else block {
            skip
        };
        };
        self.bets := (Map.empty : map(nat, roulette_Bet));
        self.requiredBalance := 0tez;

        const tmp_1 : (list(operation) * storage) = cashOut(self);
        var listOp : list(operation) := tmp_1.0;
        var store : storage := tmp_1.1;
    } with (listOp, store);

    function main (const action : entryAction; const self : storage) : (list(operation) * storage) is
    block {
        skip
    } with case action of
    | InitGame -> ((nil : list(operation)), init(self))
    | Fund -> ((nil : list(operation)), fund(self))
    | Bet(params) -> ((nil : list(operation)), bet(self, params.number, params.betType))
    | StartRoulette(params) -> startRoulette(self, params.result)
    | BanUser(params) -> ((nil : list(operation)), banUser(self, params.player))
    | UnbanUser(params) -> ((nil : list(operation)), unbanUser(self, params.player))
    end