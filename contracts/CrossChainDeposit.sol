// SPDX-License-Identifier: Apache 2

pragma solidity ^0.7.6;
pragma abicoder v2;

import './SwapHelper.sol';
import './ITokenBridge.sol';
import 'solidity-bytes-utils/contracts/BytesLib.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';


interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}


/// @title A cross-chain UniswapV3 example
/// @notice Swaps against UniswapV3 pools and uses Wormhole TokenBridge
/// for cross-chain transfers
contract CrossChainDeposit {
    using SafeERC20 for IERC20;
    using BytesLib for bytes;
    IUniswapRouter public immutable SWAP_ROUTER;
    address public immutable TOKEN_BRIDGE_ADDRESS;

    constructor(
        address _swapRouterAddress,
        address _tokenBridgeAddress
    ) {
        SWAP_ROUTER = IUniswapRouter(_swapRouterAddress);
        TOKEN_BRIDGE_ADDRESS = _tokenBridgeAddress;
    }

    /// @dev Returns the parsed TokenBridge payload which contains swap
    /// instructions after redeeming the VAA from the TokenBridge
    function _getParsedPayload(
        bytes calldata encodedVaa
    ) private returns (SwapHelper.DecodedVaaParameters memory payload) {
        // complete the transfer on the token bridge
        bytes memory vmPayload = ITokenBridge(
            TOKEN_BRIDGE_ADDRESS
        ).completeTransferWithPayload(encodedVaa);

        // parse the payload
        payload = _parsePayload(vmPayload);
    }

    function _parsePayload(
        bytes memory vmPayload
    ) private returns (SwapHelper.DecodedVaaParameters memory payload) {
        // first we parse the token bridge payload
        payload.transferPayload = ITokenBridge(TOKEN_BRIDGE_ADDRESS).parseTransferWithPayload(vmPayload);

        // then we parse out the other payload
        payload.customPayload = SwapHelper.decodeVaaPayload(payload.transferPayload.payload);
    }

    /// @dev Executes asset swap and pays the relayer
    function recvAndSwap(
        bytes calldata encodedVaa
    ) external returns (uint256) {
        // redeem and fetch parsed payload
        SwapHelper.DecodedVaaParameters memory payload =
            _getParsedPayload(encodedVaa);

        // get the address for wh wrapped tokens that were just sent to this contract from the token bridge
        address wrappedAssetAddress = ITokenBridge(TOKEN_BRIDGE_ADDRESS).wrappedAsset(payload.transferPayload.tokenChain, payload.transferPayload.tokenAddress);

        // approve the router to spend wormhole wrapped tokens
        TransferHelper.safeApprove(
            wrappedAssetAddress,
            address(SWAP_ROUTER),
            payload.transferPayload.amount
        );

        // set swap options with user params
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: wrappedAssetAddress,
                tokenOut: payload.customPayload.targetToken,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: payload.transferPayload.amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // try to execute the swap
        try SWAP_ROUTER.exactInputSingle(params) returns (uint256 amountOut) {
            return amountOut;
        } catch {
            // swap failed - return basic wh wrapped asset to recipient
            IERC20 wrappedAsset = IERC20(wrappedAssetAddress);
            wrappedAsset.safeTransfer(
                payload.customPayload.recipientAddress,
                payload.transferPayload.amount
            );
        }
    }

    /// @dev Calls _swapExactInBeforeTransfer and encodes custom payload with
    /// instructions for executing the swap on the target chain.
    function sendDeposit(
        address token,
        bytes32 targetChainRecipient,
        address targetChainCurrency,
        uint16 targetChainId,
        bytes32 targetContractAddress,
        uint256 amountOut,
        uint32 nonce
    ) external payable {
        // create payload with target swap instructions
        bytes memory payload = abi.encodePacked(
            targetChainRecipient,
            targetChainCurrency
        );

        // approve token bridge to spend feeTokens
        TransferHelper.safeApprove(
            token,
            TOKEN_BRIDGE_ADDRESS,
            amountOut
        );

        // send transfer with payload to the TokenBridge
        ITokenBridge(TOKEN_BRIDGE_ADDRESS).transferTokensWithPayload(
            token,
            amountOut,
            targetChainId,
            targetContractAddress,
            nonce,
            payload
        );
    }

    // necessary for receiving native assets
    receive() external payable {}
}
