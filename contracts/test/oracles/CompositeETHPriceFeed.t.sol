// SPDX-License-Identifier: UNLICENSED
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { CompositeETHPriceFeed } from "../../oracles/CompositeETHPriceFeed.sol";
import { PriceFeedMock } from "../mocks/oracles/PriceFeedMock.sol";
import { IPriceOracleV2Exceptions } from "../../interfaces/IPriceOracle.sol";

import { CheatCodes, HEVM_ADDRESS } from "../lib/cheatCodes.sol";
import "../lib/test.sol";
import "../lib/constants.sol";

// SUITES
import { TokensTestSuite } from "../suites/TokensTestSuite.sol";

// EXCEPTIONS
import { NotImplementedException, CallerNotConfiguratorException } from "../../interfaces/IErrors.sol";

/// @title CompositeETHPriceFeedTest
/// @notice Designed for unit test purposes only
contract CompositeETHPriceFeedTest is DSTest, IPriceOracleV2Exceptions {
    CheatCodes evm = CheatCodes(HEVM_ADDRESS);

    PriceFeedMock public targetPf;
    PriceFeedMock public ethUsdPf;
    CompositeETHPriceFeed public pf;

    TokensTestSuite tokenTestSuite;

    function setUp() public {
        targetPf = new PriceFeedMock(99 * 10**16, 18);
        ethUsdPf = new PriceFeedMock(1000 * 10**8, 8);
        pf = new CompositeETHPriceFeed(address(targetPf), address(ethUsdPf));
    }

    ///
    ///
    ///  TESTS
    ///
    ///

    /// @dev [CEPF-1]: constructor sets correct values
    function test_CEPF_01_constructor_sets_correct_values() public {
        assertEq(
            pf.description(),
            "price oracle ETH/USD Composite",
            "Incorrect description"
        );

        assertEq(pf.decimals(), 8, "Incorrect decimals");

        assertEq(
            pf.ethPriceFeedDecimals(),
            18,
            "Incorrect ETH price feed decimals"
        );

        assertTrue(pf.skipPriceCheck(), "Incorrect skipPriceCheck");
    }

    /// @dev [CEPF-2]: getRoundData reverts
    function test_CEPF_02_getRoundData_reverts() public {
        evm.expectRevert(NotImplementedException.selector);

        pf.getRoundData(1);
    }

    /// @dev [CEPF-3]: latestRoundData works correctly
    function test_CEPF_03_latestRoundData_works_correctly(
        int256 answer1,
        int256 answer2
    ) public {
        evm.assume(answer1 > 0);
        evm.assume(answer2 > 0);
        evm.assume(answer1 < int256(RAY));
        evm.assume(answer2 < int256(RAY));

        targetPf.setPrice(answer1);
        ethUsdPf.setPrice(answer2);

        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = pf.latestRoundData();
        (
            uint80 roundIdTarget,
            int256 answerTarget,
            uint256 startedAtTarget,
            uint256 updatedAtTarget,
            uint80 answeredInRoundTarget
        ) = targetPf.latestRoundData();
        (, int256 answerEth, , , ) = ethUsdPf.latestRoundData();

        assertEq(roundId, roundIdTarget, "Incorrect round Id #1");
        assertEq(
            answer,
            (answerTarget * answerEth) / int256(10**targetPf.decimals()),
            "Incorrect answer #1"
        );
        assertEq(startedAt, startedAtTarget, "Incorrect startedAt #1");
        assertEq(updatedAt, updatedAtTarget, "Incorrect updatedAt #1");
        assertEq(
            answeredInRound,
            answeredInRoundTarget,
            "Incorrect answeredInRound #1"
        );
    }

    /// @dev [CEPF-4]: latestRoundData reverts on failing sanity checks
    function test_CEPF_04_latestRoundData_reverts_on_incorrect_answers()
        public
    {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = targetPf.latestRoundData();

        targetPf.setParams(roundId, startedAt, 0, answeredInRound);

        evm.expectRevert(ChainPriceStaleException.selector);
        pf.latestRoundData();

        targetPf.setParams(roundId, startedAt, updatedAt, roundId - 1);

        evm.expectRevert(ChainPriceStaleException.selector);
        pf.latestRoundData();

        targetPf.setParams(roundId, startedAt, updatedAt, answeredInRound);

        targetPf.setPrice(0);

        evm.expectRevert(ZeroPriceException.selector);
        pf.latestRoundData();

        targetPf.setPrice(99 * 10**16);

        (roundId, answer, startedAt, updatedAt, answeredInRound) = ethUsdPf
            .latestRoundData();

        ethUsdPf.setParams(roundId, startedAt, 0, answeredInRound);

        evm.expectRevert(ChainPriceStaleException.selector);
        pf.latestRoundData();

        ethUsdPf.setParams(roundId, startedAt, updatedAt, roundId - 1);

        evm.expectRevert(ChainPriceStaleException.selector);
        pf.latestRoundData();

        ethUsdPf.setParams(roundId, startedAt, updatedAt, answeredInRound);

        ethUsdPf.setPrice(0);

        evm.expectRevert(ZeroPriceException.selector);
        pf.latestRoundData();
    }
}
