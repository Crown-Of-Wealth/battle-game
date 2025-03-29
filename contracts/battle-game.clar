;; title: Battle Game
;; version: 1.0
;; summary: A turn-based PvP battle game on Stacks using Clarity
;; description: 
;; This smart contract allows two players to engage in a turn-based battle. 
;; Each player starts with a set amount of HP and takes turns attacking their opponent. 
;; The game ends when one player's HP reaches zero, declaring the other player the winner. 
;; The contract ensures fair play by enforcing turn-based mechanics and preventing further actions once a game is over.
;; traits
;; (None required for this contract)
;; token definitions
;; (Not applicable in this version)
;; constants
;;
(define-constant STARTING_HP u100)
;; data vars
;; (No standalone variables; all data is stored in maps)
;; data maps
;;
(define-map battles
  {player1: principal, player2: principal}
  {hp1: uint, hp2: uint, turn: principal, winner: (optional principal)})
;; public functions
;;
(define-public (start-game (opponent principal))
  (begin
    (asserts! (not (is-eq tx-sender opponent)) (err "Cannot play against yourself"))
    (asserts! (is-none (map-get? battles {player1: tx-sender, player2: opponent}))
      (err "Game already exists"))
    (asserts! (is-none (map-get? battles {player1: opponent, player2: tx-sender}))
      (err "Game already exists with opponent as player1"))
    (map-set battles {player1: tx-sender, player2: opponent} {hp1: STARTING_HP, hp2: STARTING_HP, turn: tx-sender, winner: none})
    (ok "Game started")))

(define-public (attack (opponent principal))
  (begin
    (asserts! (not (is-eq tx-sender opponent)) (err "Cannot attack yourself"))
    (let ((battle (map-get? battles {player1: tx-sender, player2: opponent})))
      (match battle 
        battle-data
          (let ((new-hp2 (- (get hp2 battle-data) u10)))
            (asserts! (is-eq (get turn battle-data) tx-sender) (err "Not your turn"))
            (asserts! (is-none (get winner battle-data)) (err "Game already over"))
            (if (<= new-hp2 u0)
                (begin
                  (map-set battles {player1: tx-sender, player2: opponent}
                    {hp1: (get hp1 battle-data), hp2: u0, turn: opponent, winner: (some tx-sender)})
                  (ok "You win!"))
                (begin
                  (map-set battles {player1: tx-sender, player2: opponent}
                    {hp1: (get hp1 battle-data), hp2: new-hp2, turn: opponent, winner: none})
                  (ok "Attack successful"))))
        (err "Game not found")))))

(define-public (counter-attack (opponent principal))
  (begin
    (asserts! (not (is-eq tx-sender opponent)) (err "Cannot attack yourself"))
    (let ((battle (map-get? battles {player1: opponent, player2: tx-sender})))
      (match battle 
        battle-data
          (let ((new-hp1 (- (get hp1 battle-data) u10)))
            (asserts! (is-eq (get turn battle-data) tx-sender) (err "Not your turn"))
            (asserts! (is-none (get winner battle-data)) (err "Game already over"))
            (if (<= new-hp1 u0)
                (begin
                  (map-set battles {player1: opponent, player2: tx-sender}
                    {hp1: u0, hp2: (get hp2 battle-data), turn: opponent, winner: (some tx-sender)})
                  (ok "You win!"))
                (begin
                  (map-set battles {player1: opponent, player2: tx-sender}
                    {hp1: new-hp1, hp2: (get hp2 battle-data), turn: opponent, winner: none})
                  (ok "Attack successful"))))
        (err "Game not found")))))

;; read only functions
;;
(define-read-only (get-game (player1 principal) (player2 principal))
  (map-get? battles {player1: player1, player2: player2}))

;; private functions
;; (None in this version)