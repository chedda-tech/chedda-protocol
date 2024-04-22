# Solidity API

## CheddaTokenBridged

CHEDDA token contract deployed to chains other than the base chain.

### constructor

```solidity
constructor(address lzEndpoint, address delegate) public
```

Construct a new Chedda token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| lzEndpoint | address | The LayerZero endpoint. |
| delegate | address | The contract owner. Can configure OFT. |

