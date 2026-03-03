# Contract Documentation

API reference for Chedda Protocol contracts, organized by module.

## Pool

- [LendingPool](pool/LendingPool.md) — ERC4626 vault implementing supply, borrow, and liquidation
- [ILendingPool](pool/ILendingPool.md) — LendingPool interface
- [IFlashLiquidationCallback](pool/IFlashLiquidationCallback.md) — Callback interface for flash liquidations

## Tokens

- [DebtToken](tokens/DebtToken.md) — Non-transferrable ERC4626 token tracking borrower debt
- [CXToken](tokens/CXToken.md) — Collateral wrapper token
- [CheddaOFTAdapter](tokens/CheddaOFTAdapter.md) — LayerZero OFT adapter for cross-chain CHEDDA
- [CheddaTokenBridged](tokens/CheddaTokenBridged.md) — Bridged CHEDDA token on non-home chains

## Rewards

- [CheddaToken](rewards/CheddaToken.md) — OFT token with halving emission schedule
- [CheddaLockingGauge](rewards/CheddaLockingGauge.md) — Time-locked CHEDDA staking with boost multipliers
- [StakingPool](rewards/StakingPool.md) — Generic ERC20 staking with CHEDDA rewards
- [LockingGaugeRewardsDistributor](rewards/LockingGaugeRewardsDistributor.md) — Distributes emissions across pools
- [ICheddaToken](rewards/ICheddaToken.md) — CheddaToken interface
- [ICheddaPool](rewards/ICheddaPool.md) — Pool interface for rewards integration
- [ILockingGauge](rewards/ILockingGauge.md) — Locking gauge interface
- [IStakingPool](rewards/IStakingPool.md) — Staking pool interface
- [IRewardsDistributor](rewards/IRewardsDistributor.md) — Rewards distributor interface

## Oracle

- [DIAPriceFeed](oracle/DIAPriceFeed.md) — DIA oracle adapter for token price feeds
- [IPriceFeed](oracle/IPriceFeed.md) — Price feed interface
- [IDIAOracleV2](oracle/IDIAOracleV2.md) — DIA oracle V2 interface

## Interest Rates

- [DefaultInterestRateModel](interestrates/DefaultInterestRateModel.md) — Two-slope kinked interest rate curve
- [IInterestRateModel](interestrates/IInterestRateModel.md) — Interest rate model interface
- [InterestRatesProjector](interestrates/InterestRatesProjector.md) — Utility for projecting rate curves

## Config

- [AddressRegistry](config/AddressRegistry.md) — Central registry for protocol addresses and pool management
- [IAddressRegistry](config/IAddressRegistry.md) — AddressRegistry interface

## Lens

- [LendingPoolLens](lens/LendingPoolLens.md) — Read-only view functions for pool state
- [AccountActor](lens/AccountActor.md) — Batch account operations

## Library

- [MathLib](library/MathLib.md) — Math utilities
