// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";

/// @title Chedda
/// @notice Chedda token
contract Chedda  is ERC20, Ownable {

    /// @notice Emitted when the new token is minted in a rebase
    /// @param caller The caller of the rebase function
    /// @param amountMinted The increase in token supply
    /// @param newTotalSupply The `totalSupply` after the rebase.
    event TokenRebased(address indexed caller, uint256 amountMinted, uint256 newTotalSupply);

    /// @notice emitted when the stkaing vault address is set.
    /// @param caller The caller of the function that triggered this event.
    /// @param vault The new staking vault address.
    event StakingVaultSet(address indexed caller, address indexed vault);

    /// @notice emitted when the gauge recipient address is set.
    /// @param caller The caller of the function that triggered this event.
    /// @param recipient The new gauge recipient address.
    event GaugeRecipientSet(address indexed caller, address indexed recipient);

    /// @dev thrown if zero-address is used where it should not be
    error ZeroAddress();

    /// @notice The inital total supply
    uint256 public constant INITIAL_SUPPLY = 400_000_000e18;

    /// @notice The number of decimals 
    uint8 public constant DECIMALS = 18;

    /// @dev The length of an epoch. Token emission reduces by half each epoch
    uint256 public constant EPOCH_LENGTH = 182.5 days;

    UD60x18 public stakingShare = ud(0.2e18);

    /// @notice the token generation event timestamp.
    uint256 immutable public tge;

    /// @notice The timestamp of the last rebase.
    uint256 public lastRebase;

    /// @notice The staking vault address that receive staking rewards.
    address public stakingVault;

    /// @notice The gauge controller address.
    address public gaugeRecipient;

    uint256[5] private _inflationRates = [0.48e18, 0.24e18, 0.12e18, 0.06e18, 0.06e18];
    uint256[5] private _targetBaseSupply = [400_000_000e18, 592_000_000e18, 734_080_000e18, 822_169_600e18, 871_499_766e18];


    /// @notice Construct a new Chedda token.
    /// @param custodian The token custodian to mint initial supply to.
    constructor(address custodian)
    ERC20("Chedda", "CHEDDA")
    Ownable(msg.sender) {
        tge = block.timestamp;
        lastRebase = block.timestamp;
        _mint(custodian, INITIAL_SUPPLY);
    }

    /// @notice Sets the staking vault address to recieve staking rewards
    /// @dev Can only be called by `owner`. Emits StakingVaultSet(caller, vault) event 
    /// @param _vault The new staking vault
    function setStakingVault(address _vault) external onlyOwner() {
        if (_vault == address(0)) {
            revert ZeroAddress();
        }
        stakingVault = _vault;
        emit StakingVaultSet(msg.sender, _vault);
    }

    /// @notice Sets the gauge recipient address to recieve token emission rewards
    /// @dev Can only be called by `owner`. Emits GaugeRecipientSet(caller, _recipient) event 
    /// @param _recipient The new gauge recipient
    function setGaugeRecipient(address _recipient) external onlyOwner() {
        if (_recipient == address(0)) {
            revert ZeroAddress();
        }
        gaugeRecipient = _recipient;
        emit GaugeRecipientSet(msg.sender, _recipient);
    }

    /// @notice Increases the total supply of CHEDDA token according to the emission schedule.
    /// @dev Explain to a developer any extra details
    /// @return amountMinted The increment in token total supply.
    function rebase() external returns (uint256) {
        if (lastRebase >= block.timestamp) {
            return 0;
        }

        uint256 mintAmount = emissionPerSecond() * (block.timestamp - lastRebase);
        lastRebase = block.timestamp;
        if (mintAmount != 0) {
            uint256 toStakingVault = ud(mintAmount).mul(stakingShare).unwrap();
            uint256 toGaugeVault = mintAmount - toStakingVault;
            _mint(stakingVault, toStakingVault);
            _mint(gaugeRecipient, toGaugeVault);

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
