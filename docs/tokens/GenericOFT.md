# Solidity API

## GenericOFT

Generic OFT contract deployed to receive token transfers from base chain.

_Used on the other end of tokens transfered using CheddaOFTAdapter_

### constructor

```solidity
constructor(string name, string symbol, address lzEndpoint, address delegate) public
```

Construct a new Chedda token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the token |
| symbol | string | The symbol of the token |
| lzEndpoint | address | The LayerZero endpoint. |
| delegate | address | The OFT delegate. |

