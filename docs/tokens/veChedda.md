# Solidity API

## SmartWalletChecker

### check

```solidity
function check(address addr) external returns (bool)
```

## VEChedda

Explain to an end user what this does

_Explain to a developer any extra details_

### token

```solidity
address token
```

### supply

```solidity
uint256 supply
```

### epoch

```solidity
uint256 epoch
```

### locked

```solidity
mapping(address => struct VEChedda.LockedBalance) locked
```

### pointHistory

```solidity
struct VEChedda.Point[1000000000000000000] pointHistory
```

### userPointHistory

```solidity
mapping(address => struct VEChedda.Point[1000000000]) userPointHistory
```

### userPointEpoch

```solidity
mapping(address => uint256) userPointEpoch
```

### slopeChanges

```solidity
mapping(uint256 => uint256) slopeChanges
```

### controller

```solidity
address controller
```

### transfersEnabled

```solidity
bool transfersEnabled
```

### name

```solidity
string name
```

### symbol

```solidity
string symbol
```

### version

```solidity
string version
```

### decimals

```solidity
uint256 decimals
```

### futureSmartWalletChecker

```solidity
address futureSmartWalletChecker
```

### smartWalletChecker

```solidity
address smartWalletChecker
```

### admin

```solidity
address admin
```

### futureAdmin

```solidity
address futureAdmin
```

### DEPOSIT_FOR_TYPE

```solidity
int128 DEPOSIT_FOR_TYPE
```

### CREATE_LOCK_TYPE

```solidity
int128 CREATE_LOCK_TYPE
```

### INCREASE_LOCK_AMOUNT

```solidity
int128 INCREASE_LOCK_AMOUNT
```

### INCREASE_UNLOCK_TIME

```solidity
int128 INCREASE_UNLOCK_TIME
```

### ZERO_ADDRESS

```solidity
address ZERO_ADDRESS
```

### WEEK

```solidity
uint256 WEEK
```

### MAXTIME

```solidity
uint256 MAXTIME
```

### MULTIPLIER

```solidity
uint256 MULTIPLIER
```

### Point

```solidity
struct Point {
  uint256 bias;
  uint256 slope;
  uint256 ts;
  uint256 blk;
}
```

### LockedBalance

```solidity
struct LockedBalance {
  uint256 amount;
  uint256 end;
}
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### constructor

```solidity
constructor(address tokenAddr, string _name, string _symbol, string _version) public
```

Contract constructor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddr | address | `ERC20CRV` token address |
| _name | string | Token name |
| _symbol | string | Token symbol |
| _version | string | Contract version - required for Aragon compatibility |

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### EMPTY_POINT_FACTORY

```solidity
function EMPTY_POINT_FACTORY() internal pure returns (struct VEChedda.Point)
```

### EMPTY_LOCKED_BALANCE_FACTORY

```solidity
function EMPTY_LOCKED_BALANCE_FACTORY() internal pure returns (struct VEChedda.LockedBalance)
```

### getLastUserSlope

```solidity
function getLastUserSlope(address addr) external view returns (uint256)
```

Get the most recently recorded rate of voting power decrease for `addr`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Address of the user wallet |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Value of the slope |

### userPointHistoryTS

```solidity
function userPointHistoryTS(address _addr, uint256 _idx) external view returns (uint256)
```

Get the timestamp for checkpoint `_idx` for `_addr`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _addr | address | User wallet address |
| _idx | uint256 | User epoch number |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Epoch time of the checkpoint |

### lockedEnd

```solidity
function lockedEnd(address _addr) external view returns (uint256)
```

Get timestamp when `_addr`'s lock finishes

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _addr | address | User wallet |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Epoch time of the lock end |

### lockedAmount

```solidity
function lockedAmount(address _addr) external view returns (uint256)
```

Get the amount `_addr` has locked.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _addr | address | User wallet |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of underlying token locked. |

### balanceOf

```solidity
function balanceOf(address addr, uint256 _t) public view returns (uint256)
```

Get the current voting power for `msg.sender` at the specified timestamp

_Adheres to the ERC20 `balanceOf` interface for Aragon compatibility_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | User wallet address |
| _t | uint256 | Epoch time to return voting power at |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | User voting power |

### balanceOf

```solidity
function balanceOf(address addr) public view returns (uint256)
```

Get the current voting power for `msg.sender` at the current timestamp

_Adheres to the ERC20 `balanceOf` interface for Aragon compatibility_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | User wallet address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | User voting power |

### balanceOfAt

```solidity
function balanceOfAt(address addr, uint256 _block) external view returns (uint256)
```

Measure voting power of `addr` at block height `_block`

_Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | User's wallet address |
| _block | uint256 | Block to calculate the voting power at |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Voting power |

### totalSupply

```solidity
function totalSupply(uint256 t) public view returns (uint256)
```

Calculate total voting power at the specified timestamp

_Adheres to the ERC20 `totalSupply` interface for Aragon compatibility_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total voting power |

### totalSupply

```solidity
function totalSupply() public view returns (uint256)
```

Calculate total voting power at the current timestamp

_Adheres to the ERC20 `totalSupply` interface for Aragon compatibility_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total voting power |

### totalSupplyAt

```solidity
function totalSupplyAt(uint256 _block) external view returns (uint256)
```

Calculate total voting power at some point in the past

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _block | uint256 | Block to calculate the total voting power at |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total voting power at `_block` |

### _assertNotContract

```solidity
function _assertNotContract(address addr) internal
```

Check if the call is from a whitelisted smart contract, revert if not

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Address to be checked |

### _checkpoint

```solidity
function _checkpoint(address addr, struct VEChedda.LockedBalance oldLocked, struct VEChedda.LockedBalance newLocked) internal returns (struct VEChedda.Point)
```

Record global and per-user data to checkpoint

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | User's wallet address. No user checkpoint if 0x0 |
| oldLocked | struct VEChedda.LockedBalance | Previous locked amount / end lock time for the user |
| newLocked | struct VEChedda.LockedBalance | New locked amount / end lock time for the user |

### _checkpointPartTwo

```solidity
function _checkpointPartTwo(address addr, uint256 _bias, uint256 _slope) internal returns (struct VEChedda.Point)
```

Needed for 'stack too deep' issues in _checkpoint()

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | User's wallet address. No user checkpoint if 0x0 |
| _bias | uint256 | from unew |
| _slope | uint256 | from unew |

### _depositFor

```solidity
function _depositFor(address _addr, uint256 _value, uint256 unlockTime, struct VEChedda.LockedBalance lockedBalance, int128 _type) internal returns (struct VEChedda.Point newPoint)
```

Deposit and lock tokens for a user

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _addr | address | User's wallet address |
| _value | uint256 | Amount to deposit |
| unlockTime | uint256 | New time when to unlock the tokens, or 0 if unchanged |
| lockedBalance | struct VEChedda.LockedBalance | Previous locked amount / timestamp |
| _type | int128 |  |

### findBlockEpoch

```solidity
function findBlockEpoch(uint256 _block, uint256 maxEpoch) internal view returns (uint256)
```

Binary search to estimate timestamp for block number

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _block | uint256 | Block to find |
| maxEpoch | uint256 | Don't go beyond this epoch |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Approximate timestamp for block |

### supplyAt

```solidity
function supplyAt(struct VEChedda.Point point, uint256 t) internal view returns (uint256)
```

Calculate total voting power at some point in the past

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| point | struct VEChedda.Point | The point (bias/slope) to start search from |
| t | uint256 | Time to calculate the total voting power at |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total voting power at that time |

### checkpoint

```solidity
function checkpoint(address) external
```

Record global data to checkpoint

### depositFor

```solidity
function depositFor(address _addr, uint256 _value) external
```

Deposit and lock tokens for a user

_Anyone (even a smart contract) can deposit for someone else, but
        cannot extend their locktime and deposit for a brand new user_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _addr | address | User's wallet address |
| _value | uint256 | Amount to add to user's lock |

### createLock

```solidity
function createLock(uint256 _value, uint256 _unlockTime) external returns (struct VEChedda.Point)
```

Deposit `_value` tokens for `msg.sender` and lock until `_unlockTime`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _value | uint256 | Amount to deposit |
| _unlockTime | uint256 | Epoch time when tokens unlock, rounded down to whole weeks |

### increaseAmount

```solidity
function increaseAmount(uint256 _value) external returns (struct VEChedda.Point)
```

Deposit `_value` additional tokens for `msg.sender`
        without modifying the unlock time

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _value | uint256 | Amount of tokens to deposit and add to the lock |

### increaseUnlockTime

```solidity
function increaseUnlockTime(uint256 _unlockTime) external returns (struct VEChedda.Point)
```

Extend the unlock time for `msg.sender` to `_unlockTime`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _unlockTime | uint256 | New epoch time for unlocking |

### withdraw

```solidity
function withdraw() external returns (struct VEChedda.Point)
```

Withdraw all tokens for `msg.sender`ime`

_Only possible if the lock has expired_

### commitTransferOwnership

```solidity
function commitTransferOwnership(address addr) external
```

Transfer ownership of VotingEscrow contract to `addr`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Address to have ownership transferred to |

### applyTransferOwnership

```solidity
function applyTransferOwnership() external
```

Apply ownership transfer

### commitSmartWalletChecker

```solidity
function commitSmartWalletChecker(address addr) external
```

Set an external contract to check for approved smart contract wallets

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Address of Smart contract checker |

### applySmartWalletChecker

```solidity
function applySmartWalletChecker() external
```

Apply setting external contract to check approved smart contract wallets

### changeController

```solidity
function changeController(address _newController) external
```

Dummy method for compatibility with Aragon

_Dummy method required for Aragon compatibility_

### recoverERC20

```solidity
function recoverERC20(address tokenAddress, uint256 tokenAmount) external
```

### _blockTimestamp

```solidity
function _blockTimestamp() internal view returns (uint256)
```

### _blockNumber

```solidity
function _blockNumber() internal view returns (uint256)
```

### Recovered

```solidity
event Recovered(address token, uint256 amount)
```

### CommitOwnership

```solidity
event CommitOwnership(address admin)
```

### ApplyOwnership

```solidity
event ApplyOwnership(address admin)
```

### Deposit

```solidity
event Deposit(address provider, uint256 value, uint256 locktime, int128 _type, uint256 ts)
```

### Withdraw

```solidity
event Withdraw(address provider, uint256 value, uint256 ts)
```

### Supply

```solidity
event Supply(uint256 prevSupply, uint256 supply)
```

