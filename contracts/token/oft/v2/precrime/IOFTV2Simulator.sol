// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@layerzerolabs/lz-evm-oapp-v2/contracts/standards/precrime/interfaces/IPreCrimeV2Simulator.sol";

interface IOFTV2Simulator is IPreCrimeV2Simulator {

    function tvlSD() external view returns (uint64);

    function isProxy() external pure returns (bool);
}
