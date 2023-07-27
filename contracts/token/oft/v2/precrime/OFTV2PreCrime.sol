// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@layerzerolabs/lz-evm-oapp-v2/contracts/standards/precrime/extensions/PreCrimeV2E1.sol";
import "./IOFTV2Simulator.sol";

/// @title A pre-crime contract for tokens with one ProxyOFTV2 and multiple OFTV2 contracts
/// @notice Ensures that the total supply on all chains will remain the same when tokens are transferred between chains
/// @dev This contract must only be used for tokens with fixed total supply
contract OFTV2PreCrime is PreCrimeV2E1 {

    constructor(
        uint32 _localEid,
        address _endpoint,
        address _oftSimulator
    ) PreCrimeV2E1(_localEid, _endpoint, _oftSimulator) {
    }

    function simulationCallback() external view returns (bytes memory) {
        uint64 tvlSD = IOFTV2Simulator(simulator).tvlSD();
        bool isProxy = IOFTV2Simulator(simulator).isProxy();
        return abi.encodePacked(tvlSD, isProxy);
    }

    function _getPreCrimePeers(
        InboundPacket[] memory _packets
    ) internal override returns (uint32[] memory eids, bytes32[] memory peers) {
        for (uint i = 0; i < _packets.length; i++) {
            InboundPacket memory packet = _packets[i];
            if (IPreCrimeV2Simulator(simulator).isTrustedPeer(packet.srcEid, packet.sender)) {
                return (precrimePeerEids, precrimePeers);
            }
        }
        return (new uint32[](0), new bytes32[](0));
    }

    function _precrime(InboundPacket[] memory _packets, bytes[] calldata _simulations) internal override {
        uint srcTvlSD = 0;
        uint dstTvlSD = 0;

        for (uint i = 0; i < _simulations.length; i++) {
            bytes calldata simulation = _simulations[i];

            uint32 eid = uint32(bytes4(simulation[0:4]));
            uint64 tvlSD = uint64(bytes8(simulation[4:12]));
            bool isProxy = uint8(simulation[12]) == 1;

            if (isProxy) {
                if (srcTvlSD > 0) revert InvalidSimulationResult(eid);
                srcTvlSD = tvlSD;
            } else {
                dstTvlSD += tvlSD;
            }
        }

        if (dstTvlSD > srcTvlSD) revert CrimeFound("tvl mismatch");
    }
}
