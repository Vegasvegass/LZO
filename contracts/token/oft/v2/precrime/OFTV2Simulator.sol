// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@layerzerolabs/lz-evm-oapp-v2/contracts/standards/precrime/PreCrimeV2Simulator.sol";
import "./IOFTV2Simulator.sol";
import "../OFTCoreV2.sol";

contract OFTV2Simulator is PreCrimeV2Simulator, IOFTV2Simulator {
    using BytesLib for bytes;
    using SafeCast for uint;
    using SafeCast for uint32;

    address immutable internal oft;
    uint immutable internal ld2sdRate;

    uint64 public tvlSD;

    constructor(address _oft, address _precrime) PreCrimeV2Simulator(_precrime) {
        oft = _oft;

        (, bytes memory data) = ICommonOFT(_oft).token().staticcall(abi.encodeWithSignature("decimals()"));
        uint8 decimals = abi.decode(data, (uint8));
        uint8 sharedDecimals = OFTCoreV2(_oft).sharedDecimals();
        ld2sdRate = 10**(decimals - sharedDecimals);
    }

    function _beforeSimulation(InboundPacket[] calldata _packets) internal virtual override {
        tvlSD = (IERC20(oft).totalSupply() / ld2sdRate).toUint64();
    }

    function _lzReceive(
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes32 _guid,
        bytes calldata _message
    ) internal virtual override {
        uint64 amountSD = _getAmountSDFromMessage(_message);
        tvlSD += amountSD;
    }

    function _getAmountSDFromMessage(bytes calldata _message) internal pure returns (uint64) {
        return uint64(bytes8(_message[33:41]));
    }

    function oapp() external view returns (address) {
        return oft;
    }

    function isTrustedPeer(uint32 _eid, bytes32 _peer) public view override (IPreCrimeV2Simulator, PreCrimeV2Simulator) returns (bool) {
        bytes memory path = OFTCoreV2(oft).trustedRemoteLookup(_eid.toUint16());
        uint pathLength = path.length;
        require(pathLength > 20 && pathLength <= 52, "OFTV2View: invalid path length");

        bytes32 expectedPeer = bytes32(path.slice(0, pathLength - 20));
        unchecked {
            uint offset = 52 - path.length;
            expectedPeer = expectedPeer >> (offset * 8);
        }

        return expectedPeer == _peer;
    }

    function isProxy() external pure virtual returns (bool) {
        return false;
    }
}
