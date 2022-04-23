// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {Auth} from "solmate/auth/Auth.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";

interface USDCVault is ERC4626, Auth {

  function totalAssets() public view override returns (uint256 totalFunds) {}

  function afterDeposit(uint256 assets, uint256 shares) internal virtual overrides {}

  function beforeWithdraw(uint256 assets, uint256 shares) internal virtual overrides {}

  function useFunds(uint256 funds) external requiresAuth {}

  function returnFunds(uint256 funds) external requiresAuth {}
    
}
 
