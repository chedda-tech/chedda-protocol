# Solidity API

## IFlashLiquidationCallback

Interface specifying flash liquidation callback contract.

### execute

```solidity
function execute(bytes data) external
```

Function to be executed during a flash liquidation.

_This function is called by the lending pool. This contains any logic
such as swap liquidated collateral tokens for asset tokens and return asset tokens
to pool._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| data | bytes | encoded data parameter containing all information required by the function call. |

