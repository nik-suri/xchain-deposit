// SPDX-License-Identifier: Apache 2

pragma solidity ^0.7.6;
pragma abicoder v2;

import './ITokenBridge.sol';
import "./Structs.sol";
import 'solidity-bytes-utils/contracts/BytesLib.sol';

/// @title Helper library for cross-chain swaps
/// @notice Contains functions necessary for parsing encoded VAAs
/// and structs containing swap parameters
library SwapHelper {
    using BytesLib for bytes;

    struct CustomPayload {
        address recipientAddress;
        address targetToken;
    }

    /// @dev Parameters parsed from a VAA for executing swaps
    /// on the destination chain
    struct DecodedVaaParameters {
        // Token Bridge TransferWithPayload named params
        Structs.TransferWithPayload transferPayload;
        CustomPayload customPayload;
    }

    /// @dev Decodes parameters encoded in a VAA
    function decodeVaaPayload(
        bytes memory customPayload
    ) public view returns (CustomPayload memory decoded) {
        uint index = 0;

        decoded.recipientAddress = customPayload.toAddress(index);
        index += 32;

        decoded.targetToken = customPayload.toAddress(index);
        index += 32;

        require(customPayload.length == index, "invalid payload length");
    }
}