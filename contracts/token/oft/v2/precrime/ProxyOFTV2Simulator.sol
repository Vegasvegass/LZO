// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OFTV2Simulator.sol";
import "../ProxyOFTV2.sol";

contract ProxyOFTV2Simulator is OFTV2Simulator {
    using SafeCast for uint;

    constructor(address _oft, address _precrime) OFTV2Simulator(_oft, _precrime) {}

    function _beforeSimulation(InboundPacket[] calldata _packets) internal virtual override {
        tvlSD = (ProxyOFTV2(oft).outboundAmount() / ld2sdRate).toUint64();
    }

    function _lzReceive(
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes32 _guid,
        bytes calldata _message
    ) internal virtual override {
        uint64 amountSD = _getAmountSDFromMessage(_message);
        tvlSD -= amountSD;
    }

    function isProxy() external pure override returns (bool) {
        return true;
    }
}
