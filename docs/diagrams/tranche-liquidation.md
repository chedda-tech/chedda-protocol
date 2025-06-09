```mermaid
sequenceDiagram
    participant Liquidator
    participant BorrowManager
    participant Oracle
    participant CollateralToken (ERC20)
    participant LoanAssetVault (ERC20)

    Note over BorrowManager: 📉 Periodic solvency check
    BorrowManager->>Oracle: fetch latest prices

    Note over BorrowManager: 🛑 Borrower health factor is below threshold
    Liquidator->>BorrowManager: triggerLiquidation(borrower)

    BorrowManager->>CollateralToken (ERC20): seize borrower's collateral
    BorrowManager->>Liquidator: transfer seized collateral (discounted price)

    Note over BorrowManager, Liquidator: 💰 Loan repayment
    Liquidator->>LoanAssetVault (ERC20): repay part or all of borrower's debt
    BorrowManager->>Liquidator: keep remaining seized collateral as reward

    BorrowManager: update borrower's debt balance

```