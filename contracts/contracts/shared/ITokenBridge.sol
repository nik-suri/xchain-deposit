// SPDX-License-Identifier: Apache 2

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Structs.sol";

interface ITokenBridge {
  function transferTokensWithPayload(
      address token,
      uint256 amount,
      uint16 recipientChain,
      bytes32 recipient,
      uint32 nonce,
      bytes memory payload
    ) external payable returns (uint64);

    function completeTransferWithPayload(
        bytes memory encodedVm
    ) external returns (bytes memory);

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) external view returns (address);

    function parseTransferWithPayload(bytes memory encoded) external pure returns (Structs.TransferWithPayload memory transfer);
}