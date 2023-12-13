// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import { InterestRates } from "../contracts/pool/IInterestRatesModel.sol";
import { MockInterestRatesModel } from "./mocks/MockInterestRatesModel.sol";
import { InterestRatesProjector } from "../contracts/lens/InterestRatesProjector.sol";

contract InterestRatesProjectorTest is Test {
    
    MockInterestRatesModel public model;
    InterestRatesProjector public projector;

    function setUp() external {
        model = new MockInterestRatesModel();
        projector = new InterestRatesProjector();
    }

    function testProjection() external {
        uint256 u0 = 0;
        uint256 u1 = 0.1e18;
        uint256 u2 = 0.2e18;

        uint256[] memory utilizations = new uint256[](3);
        utilizations[0] = u0;
        utilizations[1] = u1;
        utilizations[2] = u2;
        InterestRates[] memory projections = projector.projection(address(model), utilizations);
        assertEq(projections.length, utilizations.length);

        InterestRates memory u0Rates = model.calculateInterestRates(u0);

        assertEq(projections[0].utilization, u0Rates.utilization);
        assertEq(projections[0].supplyRate, u0Rates.supplyRate);
        assertEq(projections[0].borrowRate, u0Rates.borrowRate);

        InterestRates memory u1Rates = model.calculateInterestRates(u1);

        assertEq(projections[1].utilization, u1Rates.utilization);
        assertEq(projections[1].supplyRate, u1Rates.supplyRate);
        assertEq(projections[1].borrowRate, u1Rates.borrowRate);

        InterestRates memory u2Rates = model.calculateInterestRates(u2);

        assertEq(projections[2].utilization, u2Rates.utilization);
        assertEq(projections[2].supplyRate, u2Rates.supplyRate);
        assertEq(projections[2].borrowRate, u2Rates.borrowRate);
    } 
}
