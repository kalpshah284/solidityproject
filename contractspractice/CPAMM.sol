// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./ERC20.sol";
contract CPAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    uint public reserve0;
    uint public reserve1;


    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }
    function _mint(address _to, uint _amount) private {
       balanceOf[_to] += _amount;
       totalSupply += _amount; 
    }
        function _burn(address _from, uint _amount) private {
       balanceOf[_from] -= _amount;
       totalSupply -= _amount; 
    }
    function _update(uint _reserve0, uint _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }
    function swap(address _tokenIn, uint _amountIn) external {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "invalid token"
            );
            require(_amountIn > 0, "amount in = 0");
            bool isToken0 = _tokenIn == address(token0);
            (IERC20 tokenIn,IERC20 tokenOut, uint reserveIn, uint reserveOut) = isToken0
                ? (token0,token1,reserve0,reserve1)
                : (token1, token0, reserve1, reserve0);
                tokenIn.transferFrom(msg.sender, address(this), _amountIn);
                uint amountInWithFee = (_amountIn * 997) / 1000;
                uint amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);
                tokenOut.transfer(msg.sender, amountOut);
                _update(tokenIn.balanceOf(address(this)),token1.balanceOf(address(this)));
    }
    function addLiquidity(uint _amount0,uint _amount1) external returns (uint shares) {
        
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);
        if(reserve0 > 0 || reserve1 > 0)
        require((_amount0 * reserve1) == (_amount1 * reserve0));
        if(totalSupply == 0)
        shares = _sqrt(_amount0 * _amount1);
        else 
         shares = _min(
                (_amount0 * totalSupply) / reserve0,
                (_amount1 * totalSupply) / reserve1
            );
         require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);

        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
   
    
    }
    function _sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0 (default value)
    }
    function _min(uint x , uint y) private pure returns (uint) {
        return x <= y ? x : y; 
    }
    function removeLiquidty(uint _share) external returns (uint amount0,uint amount1)  {
       uint bal0= token0.balanceOf(address(this));
       uint bal1= token1.balanceOf(address(this));
       amount0 = (_share * bal1) / totalSupply;
       amount1 = (_share * bal0) / totalSupply;
       require(amount1 > 0 && amount0 > 0,"uint bal0= token0.balanceOf(address(this));");
       _burn(msg.sender, _share);

       _update(bal0 - amount0, bal1 - amount1);
       token0.transfer(msg.sender, amount0);
       token1.transfer(msg.sender, amount1);
    }

}