# token-basic

A minimal, safe Clarity fungible token contract with owner-only minting, burning, allowances (approve / transfer-from), and basic getters.

## Features
- Owner-only mint
- Burn tokens
- Approve & transfer-from (allowances)
- Balance & allowance getters
- Total supply tracking
- Overflow / insufficient-funds guards and clear error codes

## Contract location
contracts/token-basic.clar

## Public functions
- (mint (recipient principal) (amount uint)) — owner-only mint tokens
- (burn (amount uint)) — burn caller's tokens
- (transfer (recipient principal) (amount uint)) — transfer caller → recipient
- (approve (spender principal) (amount uint)) — set allowance for spender
- (transfer-from (token-owner principal) (recipient principal) (amount uint)) — spender moves owner funds
- Read-only helpers:
  - (get-balance (user principal))
  - (get-total-supply)
  - (check-allowance (token-owner principal) (spender principal))
  - (is-owner)

## Error codes
- ERR_NOT_OWNER = u100
- ERR_INSUFFICIENT_FUNDS = u200
- ERR_NOT_ALLOWED = u300
- ERR_OVERFLOW = u400

## Build & test (local / Windows)
Prerequisites: Node.js, Clarinet (or Stacks tooling). From project root:

- Install Clarinet (if not installed):
  - npm install -g @hirosystems/clarinet
- Run tests:
  - clarinet test
- Compile/check contract with Clarinet:
  - clarinet check

(If using stacks.js or other tooling, adapt commands)

## Deploy (example using Clarinet devnet)
- Start local node:
  - clarinet console
- Deploy contract by placing file in contracts/ and running tests or using Clarinet commands that reference the contract.

## Usage examples (calls)
- Read balance:
  - clarinet query <contract> get-balance '("SP2..." )'
- Send transaction:
  - clarinet execute <contract> transfer '("SP2..." u100)'

Replace SP... with proper principal addresses provided by your devnet environment.


Add a LICENSE file to indicate project license (e.g., MIT).
