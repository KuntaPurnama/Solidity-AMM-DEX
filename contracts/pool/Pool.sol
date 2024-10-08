// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../token/LiquidityToken.sol";


//add possible error
error Pool__InvalidTokenRatio();
error Pool__ZeroLiquidityToken();
error Pool__InvalidToken();

contract Pool is LiquidityToken, ReentrancyGuard{
    IERC20 private immutable i_token0;
    IERC20 private immutable i_token1;

    uint256 private s_reserve0;
    uint256 private s_reserve1;

    uint8 private immutable i_fee;

    constructor (address token0, address token1, uint8 fee) LiquidityToken("TanoToken", "Taken"){
        i_token0 = IERC20(token0);
        i_token1 = IERC20(token1);
        i_fee = fee;
    } 

    //add event
    event SwapSuccess(
        address tokenIn,
        uint256 indexed amountIn,
        address tokenOut,
        uint256 indexed amountOut
    );

    event AddedLiquidity(
        uint256 indexed liquidityToken,
        address token0,
        uint256 amount0,
        address token1,
        uint256 indexed amount1
    );

    event RemovedLiquidity(
        uint256 indexed liquidityToken,
        address token0,
        uint256 amount0,
        address token1,
        uint256 indexed amount1
    );
    

    function _updateLiquidity(uint256 res0, uint256 res1) internal {
        s_reserve0 = res0;
        s_reserve1 = res1;
    }

    function swap(address tokenIn, uint256 amountIn) external nonReentrant{
        // Check if the token in is indeed the token we provide for swap
        require(tokenIn == address(i_token0) || tokenIn == address(i_token1), "Invalid Token");

        // Store the tokens in a temporary variable to minimize gas costs
        IERC20 token0 = i_token0;
        IERC20 token1 = i_token1;

        uint8 fee = i_fee;

        // Get amount in that we will receive
        uint256 amountInWithFee = (amountIn * (10000 - fee)) / 1000;

        // Get the reserves directly
        uint256 rIn = tokenIn == address(token0) ? s_reserve0 : s_reserve1;
        uint256 rOut = tokenIn == address(token0) ? s_reserve1 : s_reserve0;

        // Check if the target token balance is enough
        require(rOut >= amountIn, "Insufficient Balance");

        // Get amount of token that sender will receive
        uint256 amountOut = (amountInWithFee * rOut) / (rIn + amountInWithFee);

        // Perform token transfer
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Transfer token in failed");

        // Update reserves
        _updateLiquidity(
            tokenIn == address(token0) ? (rIn + amountInWithFee) : (rOut - amountOut),
            tokenIn == address(token0) ? (rOut - amountOut) : (rIn + amountInWithFee)
        );

        // Transfer the output token to the sender
        require(IERC20(token1).transfer(msg.sender, amountOut), "Transfer token out failed");

        emit SwapSuccess(tokenIn, amountIn, address(token1), amountOut);
    }

    function addLiquidity(uint256 amount0, uint256 amount1) external {
        uint256 reserve0 = s_reserve0;
        uint256 reserve1 = s_reserve1;

        //make sure non of the reserve is 0
        if (reserve0 == 0 || reserve1 == 0) {
            revert Pool__InvalidTokenRatio(); // If either reserve is zero, revert
        }

        //make sure the ratio remain the same
        if(amount0 / amount1 != reserve0/reserve1){
            revert Pool__InvalidTokenRatio();
        }


        //transfer the given amount of token from sender to contract address
        IERC20 token0 = i_token0;
        IERC20 token1 = i_token1;

        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        //calculate token that the sender will get
        uint256 liquidityTokenSupply = totalSupply();
        uint256 liquidityTokens;

        if(liquidityTokenSupply > 0){
            liquidityTokens = amount0/reserve0 * liquidityTokenSupply;
        }else{
            liquidityTokens = sqrt(amount0 * amount1);
        }

        if (liquidityTokens == 0) revert Pool__ZeroLiquidityToken();
        _mint(msg.sender, liquidityTokens);
        _updateLiquidity(reserve0 + amount0, reserve1 + amount1);

        emit AddedLiquidity(
            liquidityTokens,
            address(token0),
            amount0,
            address(token1),
            amount1
        );
    }

     function removeLiquidity(uint256 liquidityTokens) external nonReentrant {
        (uint256 amount0, uint256 amount1) = getAmountsOnRemovingLiquidity(liquidityTokens);

        _burn(msg.sender, liquidityTokens);
        _updateLiquidity(s_reserve0 - amount0, s_reserve1 - amount1);

        IERC20 token0 = i_token0; // gas optimization
        IERC20 token1 = i_token1; // gas optimization

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);

        emit RemovedLiquidity(
            liquidityTokens,
            address(token0),
            amount0,
            address(token1),
            amount1
        );
    }

    function getAmountsOnRemovingLiquidity(uint256 liquidityTokens) public view returns(uint256 amount0, uint256 amount1){
        require(liquidityTokens > 0, "0 Liquidity Tokens");

        // t = totalSupply of shares
        // s = shares
        // l = liquidity (reserve0 || reserve1)
        // dl = liquidity to be removed (amount0 || amount1)

        // The change in liquidity/token reserves should be propotional to shares burned
        // t - s/t = l - dl/l
        // dl = ls/t

        // uint256 tokenBalance = balanceOf(msg.sender);

        amount0 = (s_reserve0 * liquidityTokens) / totalSupply();
        amount1 = (s_reserve1 * liquidityTokens) / totalSupply();
    }

     function sqrt(uint256 x) public pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = (x + 1) / 2; // Initial guess
        uint256 y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2; // Update guess
        }

        return y;
    }

    function getReserves() public view returns (uint256, uint256) {
        return (s_reserve0, s_reserve1);
    }

    function getTokens() public view returns (address, address) {
        return (address(i_token0), address(i_token1));
    }

    function getFee() external view returns (uint8) {
        return i_fee;
    }

}