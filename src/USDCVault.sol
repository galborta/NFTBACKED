// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {Auth} from "solmate/auth/Auth.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

contract USDCVault is ERC4626, Auth {
  using SafeCastLib for uint256;
  using SafeTransferLib for ERC20;
  using FixedPointMathLib for uint256;
  
  /*///////////////////////////////////////////////////////////////
                              IMMUTABLES
  //////////////////////////////////////////////////////////////*/

  /// @notice The underlying token the Vault accepts.
  ERC20 public immutable UNDERLYING;

  /// @notice The base unit of the underlying token and hence rvToken.
  /// @dev Equal to 10 ** decimals. Used for fixed point arithmetic.
  uint256 internal immutable BASE_UNIT;
  
  /*///////////////////////////////////////////////////////////////
                              STORAGE
  //////////////////////////////////////////////////////////////*/

  mapping(address => uint256) private getShares; 
  mapping(address => uint256) private getTotalDeposits;

  uint256 public totalFunds;

  constructor(ERC20 _UNDERLYING)
      ERC4626(
          // Underlying token
          _UNDERLYING,
          // USDC vault 
          string(abi.encodePacked(_UNDERLYING.name(), " Vault")),
          // vUSDC 
          string(abi.encodePacked("v", _UNDERLYING.symbol()))
      )
      Auth(Auth(msg.sender).owner(), Auth(msg.sender).authority())
  {
      UNDERLYING = _UNDERLYING;

      BASE_UNIT = 10**decimals;

      // Prevent minting of vTokens until
      // the initialize function is called.
      totalSupply = type(uint256).max;
  }

  function totalAssets() public view override returns (uint256 totalFunds) {
    return (totalFunds);
  }

  function afterDeposit(uint256 assets, uint256 shares) internal virtual overrides {

    getShares[msg.sender] += shares;

    getTotalDeposits[msg.sender] += assets;

    totalFunds == assets;
  }

  function beforeWithdraw(uint256 assets, uint256 shares) internal virtual overrides {
    getShares[msg.sender] -= shares;

    getTotalDeposits[msg.sender] -= assets;

    totalFunds -= assets;
  }

  function useFunds(uint256 funds) external requiresAuth {

    UNDERLYING.safeTransferFrom(address(this), msg.sender, funds);
    totalFunds -= funds;
    
  }

  function returnFunds(uint256 funds) external requiresAuth {
    
    UNDERLYING.safeTransferFrom(address(this), msg.sender, funds);
    totalFunds += funds;

  }
    
}
