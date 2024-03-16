// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzero-v2/contracts/oft/OFT.sol";
import { IRewardsDistributor } from "../rewards/IRewardsDistributor.sol";
import { IRebaseToken } from "./IRebaseToken.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";

/// @title CheddaToken
/// @notice CheddaToken token
// TODO: Create emission controller that controls emissions.
contract CheddaToken is OFT, IRebaseToken {

    /// @notice Emitted when the new token is minted in a rebase
    /// @param caller The caller of the rebase function
    /// @param amountMinted The increase in token supply
    /// @param newTotalSupply The `totalSupply` after the rebase.
    event TokenRebased(address indexed caller, uint256 amountMinted, uint256 newTotalSupply);

    /// @notice emitted when the gauge recipient address is set.
    /// @param caller The caller of the function that triggered this event.
    /// @param receiver The new receiver address.
    event TokenReceiverSet(address indexed caller, address indexed receiver);

    /// @dev thrown if zero-address is used where it should not be
    error ZeroAddress();

    /// @notice The inital total supply
    uint256 public constant INITIAL_SUPPLY = 400_000_000e18;
    uint256 public constant MAX_TOTAL_SUPPLY = 800_000_000e18;

    /// @notice The number of decimals 
    uint8 public constant DECIMALS = 18;

    /// @dev The length of an epoch. Token emission reduces by half each epoch
    uint256 public constant EPOCH_LENGTH = 182.5 days;

    UD60x18 public stakingShare = ud(0.2e18);

    /// @notice the token generation event timestamp.
    uint256 immutable public tge;

    /// @notice The timestamp of the last rebase.
    uint256 public lastRebase;

    /// @notice The receiver for new token emissions.
    IRewardsDistributor public tokenReceiver;
    
    // TODO: Start at 32% inflation
    uint256[6] private _inflationRates = [
        0.32e18, 
        0.24e18, 
        0.16e18, 
        0.12e18, 
        0.08e18, 
        0.04e18
    ];
    uint256[6] private _targetBaseSupply = [
        400_000_000e18, 
        464_000_000e18, 
        519_680_000e18, 
        561_254_400e18, 
        594_929_664e18,
        618_726_850.056e18
    ];


    /// @notice Construct a new Chedda token.
    /// @param owner The contract owner. Initial suppply is minted to this owner.
    /// @param lzEndpoint The LayerZero endpoint.
    constructor(address owner, address lzEndpoint)
    OFT("Chedda", "CHEDDA", lzEndpoint, owner)
    Ownable(owner) {
        tge = block.timestamp;
        lastRebase = block.timestamp;
        _mint(owner, INITIAL_SUPPLY);
    }

    /// @notice Sets the address to recieve token emission. 
    /// @dev Can only be called by `owner`. Emits TokenReceiverSet(caller, _receiver) event 
    /// @param _receiver The new token recipient
    function setTokenReceiver(address _receiver) external onlyOwner() {
        if (_receiver == address(0)) {
            revert ZeroAddress();
        }
        tokenReceiver = IRewardsDistributor(_receiver);
        emit TokenReceiverSet(msg.sender, _receiver);
    }

    /// @notice Increases the total supply of CHEDDA token according to the emission schedule.
    /// @dev Explain to a developer any extra details
    /// @return amountMinted The increment in token total supply.
    function rebase() external returns (uint256) {
        if (lastRebase >= block.timestamp) {
            return 0;
        }
        if (address(tokenReceiver) == address(0)) {
            return 0;
        }

        uint256 mintAmount = emissionPerSecond() * (block.timestamp - lastRebase);
        if (mintAmount != 0) {
            lastRebase = block.timestamp;
            _mint(address(tokenReceiver), mintAmount);

            tokenReceiver.distribute();

            emit TokenRebased(msg.sender, mintAmount, totalSupply());
        }
        return mintAmount;
    }

    /// @notice Returns the amount of CHEDDA token emitted each second, 
    /// as controlled by the emission schedule.
    /// @return emission The amount of CHEDDA token emitted each second.
    function emissionPerSecond() public view returns (uint256) {
        uint256 e = epoch();
        if (e >= _inflationRates.length) {
            e = _inflationRates.length - 1;
        }
        uint256 currentInflation = _inflationRates[e];
        uint256 baseSupply = _targetBaseSupply[e];
        return ud(currentInflation).mul(ud(baseSupply)).div(ud(365.25 days * 1e18)).unwrap();
    }

    /// @notice Returns the number of the current epoch
    /// @return epoch The current epoch
    function epoch() public view returns (uint256) {
        return (block.timestamp - tge) / EPOCH_LENGTH;
    }
}
