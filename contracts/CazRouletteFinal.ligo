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
            ligoAssert(not(self.bannedUsers contains Tezos.sender), "User is banned from the game");
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

        function startRoulette(var self : storage; const result : nat) : (list(operation) * storage) is
        block {
            ligoAssert(Tezos.sender = self.gameCreator, "Tezos.sender = self.gameCreator");
            ligoAssert((size(self.bets) > 0n), "size(self.bets) > 0n");
            var ops : list(operation) := nil;
            var _final_ops : list(operation) := nil;
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
                        // Couleur Rouge : 2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35    
                        if ((result = 1n) or (result = 3n) or (result = 5n) or (result = 7n) or (result = 9n) or (result = 12n) or (result = 14n) or (result = 16n) or (result = 18n) or (result = 19n) or (result = 21n) or (result = 23n) or (result = 25n) or (result = 27n) or (result = 30n) or (result = 32n) or (result = 34n) or (result = 36n)) then block {
                                won := True;
                            } else block {
                                won := False;
                            };
                        } else block {
                            // Couleur Noire : 1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36
                            if ((result = 2n) or (result = 4n) or (result = 6n) or (result = 8n) or (result = 10n) or (result = 11n) or (result = 13n) or (result = 15n) or (result = 17n) or (result = 20n) or (result = 22n) or (result = 24n) or (result = 26n) or (result = 28n) or (result = 29n) or (result = 31n) or (result = 33n) or (result = 35n)) then block {
                            won := True;
                        } else block {
                            won := False;
                        };
                        };
                } else block {
                    skip
                };
                };
                }; 
            if (won) then block {
                const op0 : operation = transaction((unit), ((case self.winnings[b.player] of | None -> 0tez | Some(x) -> x end) + (self.betAmount * (case self.payouts[b.betType] of | None -> 0n | Some(x) -> x end))), (get_contract(b.player) : contract(unit)));
                _final_ops := op0 # ops;
                ops := _final_ops; 
            } else block {
                skip
            };
            };
            self.bets := (Map.empty : map(nat, roulette_Bet));
            self.requiredBalance := 0tez;
            
        } with (ops, self);

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