// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Pool
/// @author velodrome.finance, @figs999, @pegahcarter
/// @notice Veldrome V2 token pool, either stable or volatile
contract Pool is ERC20Permit, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string private _name;
    string private _symbol;
    address private _voter;

    ///  IPool
    bool public stable;

    uint256 internal constant MINIMUM_LIQUIDITY = 10 ** 3;
    uint256 internal constant MINIMUM_K = 10 ** 10;

    ///  IPool
    address public token0;
    ///  IPool
    address public token1;
    ///  IPool
    address public poolFees;
    ///  IPool
    address public factory;

    ///  IPool
    uint256 public constant periodSize = 1800;

    uint256 internal decimals0;
    uint256 internal decimals1;

    ///  IPool
    uint256 public reserve0;
    ///  IPool
    uint256 public reserve1;
    ///  IPool
    uint256 public blockTimestampLast;

    ///  IPool
    uint256 public reserve0CumulativeLast;
    ///  IPool
    uint256 public reserve1CumulativeLast;

    ///  IPool
    uint256 public index0;
    ///  IPool
    uint256 public index1;

    ///  IPool
    mapping(address => uint256) public supplyIndex0;
    ///  IPool
    mapping(address => uint256) public supplyIndex1;

    ///  IPool
    mapping(address => uint256) public claimable0;
    ///  IPool
    mapping(address => uint256) public claimable1;

    constructor() ERC20("", "") ERC20Permit("") {}

    ///  IPool
    function initialize(address _token0, address _token1, bool _stable) external {
        if (factory != address(0)) revert("FactoryAlreadySet()");
        factory = msg.sender;
        _voter = msg.sender;
        (token0, token1, stable) = (_token0, _token1, _stable);
        poolFees = address(123);
        string memory symbol0 = ERC20(_token0).symbol();
        string memory symbol1 = ERC20(_token1).symbol();
        if (_stable) {
            _name = string(abi.encodePacked("StableV2 AMM - ", symbol0, "/", symbol1));
            _symbol = string(abi.encodePacked("sAMMV2-", symbol0, "/", symbol1));
        } else {
            _name = string(abi.encodePacked("VolatileV2 AMM - ", symbol0, "/", symbol1));
            _symbol = string(abi.encodePacked("vAMMV2-", symbol0, "/", symbol1));
        }

        decimals0 = 10 ** ERC20(_token0).decimals();
        decimals1 = 10 ** ERC20(_token1).decimals();
    }

    ///  IPool
    function observationLength() external view returns (uint256) {
        return 0;
    }

    ///  IPool
    function metadata()
        external
        view
        returns (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, bool st, address t0, address t1)
    {
        return (decimals0, decimals1, reserve0, reserve1, stable, token0, token1);
    }

    ///  IPool
    function tokens() external view returns (address, address) {
        return (token0, token1);
    }

    ///  IPool
    function claimFees() external returns (uint256 claimed0, uint256 claimed1) {
        _updateFor(msg.sender);

        claimed0 = claimable0[msg.sender];
        claimed1 = claimable1[msg.sender];

        if (claimed0 > 0 || claimed1 > 0) {
            claimable0[msg.sender] = 0;
            claimable1[msg.sender] = 0;

            // emit Claim(msg.sender, msg.sender, claimed0, claimed1);
        }
    }

    /// @dev Accrue fees on token0
    function _update0(uint256 amount) internal {
        // Only update on this pool if there is a fee
        if (amount == 0) return;
        IERC20(token0).safeTransfer(poolFees, amount); // transfer the fees out to PoolFees
        uint256 _ratio = (amount * 1e18) / totalSupply(); // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index0 += _ratio;
        }
        // emit Fees(msg.sender, amount, 0);
    }

    /// @dev Accrue fees on token1
    function _update1(uint256 amount) internal {
        // Only update on this pool if there is a fee
        if (amount == 0) return;
        IERC20(token1).safeTransfer(poolFees, amount);
        uint256 _ratio = (amount * 1e18) / totalSupply();
        if (_ratio > 0) {
            index1 += _ratio;
        }
        // emit Fees(msg.sender, 0, amount);
    }

    /// @dev This function MUST be called on any balance changes, otherwise can be used to infinitely claim fees
    ///      Fees are segregated from core funds, so fees can never put liquidity at risk.
    function _updateFor(address recipient) internal {
        uint256 _supplied = balanceOf(recipient); // get LP balance of `recipient`
        if (_supplied > 0) {
            uint256 _supplyIndex0 = supplyIndex0[recipient]; // get last adjusted index0 for recipient
            uint256 _supplyIndex1 = supplyIndex1[recipient];
            uint256 _index0 = index0; // get global index0 for accumulated fees
            uint256 _index1 = index1;
            supplyIndex0[recipient] = _index0; // update user current position to global position
            supplyIndex1[recipient] = _index1;
            uint256 _delta0 = _index0 - _supplyIndex0; // see if there is any difference that need to be accrued
            uint256 _delta1 = _index1 - _supplyIndex1;
            if (_delta0 > 0) {
                uint256 _share = (_supplied * _delta0) / 1e18; // add accrued difference for each supplied token
                claimable0[recipient] += _share;
            }
            if (_delta1 > 0) {
                uint256 _share = (_supplied * _delta1) / 1e18;
                claimable1[recipient] += _share;
            }
        } else {
            supplyIndex0[recipient] = index0; // new users are set to the default global state
            supplyIndex1[recipient] = index1;
        }
    }

    ///  IPool
    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    /// @dev update reserves and, on the first call per block, price accumulators
    function _update(uint256 balance0, uint256 balance1, uint256 _reserve0, uint256 _reserve1) internal {
        uint256 blockTimestamp = block.timestamp;
        uint256 timeElapsed = blockTimestamp - blockTimestampLast;
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            reserve0CumulativeLast += _reserve0 * timeElapsed;
            reserve1CumulativeLast += _reserve1 * timeElapsed;
        }

        if (timeElapsed > periodSize) {}
        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = blockTimestamp;
        // emit Sync(reserve0, reserve1);
    }

    ///  IPool
    function currentCumulativePrices()
        public
        view
        returns (uint256 reserve0Cumulative, uint256 reserve1Cumulative, uint256 blockTimestamp)
    {
        blockTimestamp = block.timestamp;
        reserve0Cumulative = reserve0CumulativeLast;
        reserve1Cumulative = reserve1CumulativeLast;

        // if time has elapsed since the last update on the pool, mock the accumulated price values
        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) = getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint256 timeElapsed = blockTimestamp - _blockTimestampLast;
            reserve0Cumulative += _reserve0 * timeElapsed;
            reserve1Cumulative += _reserve1 * timeElapsed;
        }
    }

    ///  IPool
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        uint256 _balance0 = IERC20(token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(token1).balanceOf(address(this));
        uint256 _amount0 = _balance0 - _reserve0;
        uint256 _amount1 = _balance1 - _reserve1;

        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(_amount0 * _amount1) - MINIMUM_LIQUIDITY;
            _mint(address(1), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens - cannot be address(0)
            if (stable) {
                if ((_amount0 * 1e18) / decimals0 != (_amount1 * 1e18) / decimals1) revert("DepositsNotEqual()");
                if (_k(_amount0, _amount1) <= MINIMUM_K) revert("BelowMinimumK()");
            }
        } else {
            liquidity = Math.min((_amount0 * _totalSupply) / _reserve0, (_amount1 * _totalSupply) / _reserve1);
        }
        if (liquidity < MINIMUM_LIQUIDITY) revert("InsufficientLiquidityMinted()");
        _mint(to, liquidity);

        _update(_balance0, _balance1, _reserve0, _reserve1);
        // emit Mint(msg.sender, _amount0, _amount1);
    }

    ///  IPool
    function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        (address _token0, address _token1) = (token0, token1);
        uint256 _balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 _liquidity = balanceOf(address(this));

        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (_liquidity * _balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (_liquidity * _balance1) / _totalSupply; // using balances ensures pro-rata distribution
        if (amount0 == 0 || amount1 == 0) revert("InsufficientLiquidityBurned()");
        _burn(address(this), _liquidity);
        IERC20(_token0).safeTransfer(to, amount0);
        IERC20(_token1).safeTransfer(to, amount1);
        _balance0 = IERC20(_token0).balanceOf(address(this));
        _balance1 = IERC20(_token1).balanceOf(address(this));

        _update(_balance0, _balance1, _reserve0, _reserve1);
        // emit Burn(msg.sender, to, amount0, amount1);
    }

    ///  IPool
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external nonReentrant {
        // if (IPoolFactory(factosdry).isPaused()) revert("IsPaused()");
        if (amount0Out == 0 && amount1Out == 0) revert("InsufficientOutputAmount()");
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        if (amount0Out >= _reserve0 || amount1Out >= _reserve1) revert("InsufficientLiquidity()");

        uint256 _balance0;
        uint256 _balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            if (to == _token0 || to == _token1) revert("InvalidTo()");
            if (amount0Out > 0) IERC20(_token0).safeTransfer(to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) IERC20(_token1).safeTransfer(to, amount1Out); // optimistically transfer tokens
            _balance0 = IERC20(_token0).balanceOf(address(this));
            _balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = _balance0 > _reserve0 - amount0Out ? _balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = _balance1 > _reserve1 - amount1Out ? _balance1 - (_reserve1 - amount1Out) : 0;
        if (amount0In == 0 && amount1In == 0) revert("InsufficientInputAmount()");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            if (amount0In > 0) _update0(amount0In * 5 / 10000); // accrue fees for token0 and move them out of pool
            if (amount1In > 0) _update1(amount1In * 5 / 10000); // accrue fees for token1 and move them out of pool
            _balance0 = IERC20(_token0).balanceOf(address(this)); // since we removed tokens, we need to reconfirm balances, can also simply use previous balance - amountIn/ 10000, but doing balanceOf again as safety check
            _balance1 = IERC20(_token1).balanceOf(address(this));
            // The curve, either x3y+y3x for stable pools, or x*y for volatile pools
            if (_k(_balance0, _balance1) < _k(_reserve0, _reserve1)) revert("K()");
        }

        _update(_balance0, _balance1, _reserve0, _reserve1);
        // emit Swap(msg.sender, to, amount0In, amount1In, amount0Out, amount1Out);
    }

    ///  IPool
    function skim(address to) external nonReentrant {
        (address _token0, address _token1) = (token0, token1);
        IERC20(_token0).safeTransfer(to, IERC20(_token0).balanceOf(address(this)) - (reserve0));
        IERC20(_token1).safeTransfer(to, IERC20(_token1).balanceOf(address(this)) - (reserve1));
    }

    ///  IPool
    function sync() external nonReentrant {
        if (totalSupply() == 0) revert("InsufficientLiquidity()");
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        uint256 _a = (x0 * y) / 1e18;
        uint256 _b = ((x0 * x0) / 1e18 + (y * y) / 1e18);
        return (_a * _b) / 1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _get_y(uint256 x0, uint256 xy, uint256 y) internal view returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 k = _f(x0, y);
            if (k < xy) {
                // there are two cases where dy == 0
                // case 1: The y is converged and we find the correct answer
                // case 2: _d(x0, y) is too large compare to (xy - k) and the rounding error
                //         screwed us.
                //         In this case, we need to increase y by 1
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
                if (dy == 0) {
                    if (k == xy) {
                        // We found the correct answer. Return y
                        return y;
                    }
                    if (_k(x0, y + 1) > xy) {
                        // If _k(x0, y + 1) > xy, then we are close to the correct answer.
                        // There's no closer answer than y + 1
                        return y + 1;
                    }
                    dy = 1;
                }
                y = y + dy;
            } else {
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
                if (dy == 0) {
                    if (k == xy || _f(x0, y - 1) < xy) {
                        // Likewise, if k == xy, we found the correct answer.
                        // If _f(x0, y - 1) < xy, then we are close to the correct answer.
                        // There's no closer answer than "y"
                        // It's worth mentioning that we need to find y where f(x0, y) >= xy
                        // As a result, we can't return y - 1 even it's closer to the correct answer
                        return y;
                    }
                    dy = 1;
                }
                y = y - dy;
            }
        }
        revert("!y");
    }

    ///  IPool
    // NOTE: Fees hardcoded to 5 bps
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        amountIn -= (amountIn * 5) / 10000; // remove fee from amount received
        return _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    function _getAmountOut(uint256 amountIn, address tokenIn, uint256 _reserve0, uint256 _reserve1)
        internal
        view
        returns (uint256)
    {
        if (stable) {
            uint256 xy = _k(_reserve0, _reserve1);
            _reserve0 = (_reserve0 * 1e18) / decimals0;
            _reserve1 = (_reserve1 * 1e18) / decimals1;
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn = tokenIn == token0 ? (amountIn * 1e18) / decimals0 : (amountIn * 1e18) / decimals1;
            uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            return (y * (tokenIn == token0 ? decimals1 : decimals0)) / 1e18;
        } else {
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            return (amountIn * reserveB) / (reserveA + amountIn);
        }
    }

    function _k(uint256 x, uint256 y) internal view returns (uint256) {
        if (stable) {
            uint256 _x = (x * 1e18) / decimals0;
            uint256 _y = (y * 1e18) / decimals1;
            uint256 _a = (_x * _y) / 1e18;
            uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return (_a * _b) / 1e18; // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }

    /*
    @dev OZ inheritance overrides
    These are needed as _name and _symbol are set privately before
    logic is executed within the constructor to set _name and _symbol.
    */
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal {
        _updateFor(from);
        _updateFor(to);
    }
}
