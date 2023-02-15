# Cross Chain Deposits

A very important cross chain flow is to easily go from any `(source chain, source token)` to `(destination chain, destination token)`. This is useful in many different situations - from simple cross chain swaps to payments. Generally, we call this flow a "cross-chain deposit".

This repository demonstrates how to perform a very simple cross-chain swap using [wormhole](https://github.com/wormhole-foundation/wormhole). The flow is:
1. Bridge asset from the source chain to the destination chain using the wormhole token bridge.
2. Use uniswap to swap the wrapped asset on the destination chain to USDC.

Of course, there are lots of edge cases that this code doesn't handle. For example, it assumes that there is always a uniswap liquidity pool (with minimal slippage!) for the wrapped asset and USDC. Therefore, this code should be used as a reference for how to integrate with the wormhole token bridge and perform simple cross chain deposits. Ideally, projects looking to use arbitrary cross chain deposits should compose on top of high quality cross chain swaps such as [Hashflow](https://www.hashflow.com/), [Magpie](https://www.magpiefi.xyz/), or [Atlas](https://atlasdex.finance/).

Beyond deposits, payments is also a core cross chain use case. We implemented a proof-of-concept cross chain payments application, integrated with Shopify for the 2022 EthSF hackathon. See the demo video and technical description [here](https://ethglobal.com/showcase/xpay-cross-chain-payments-for-shopify-jeeqr).