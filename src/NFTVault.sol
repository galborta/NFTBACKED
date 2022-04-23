// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {Auth} from "solmate/auth/Auth.sol";

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {USDCVault} from "./interfaces/USDCVaultInterface.sol";
import {APIConsumer} from "./interfaces/APIConsumer.sol";

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract USDCVault is Auth {
  using SafeCastLib for uint256;
  using SafeTransferLib for ERC20;
  using FixedPointMathLib for uint256;

  /*///////////////////////////////////////////////////////////////
                              IMMUTABLES
  //////////////////////////////////////////////////////////////*/

  ERC721 public immutable UNDERLYING;

  address public immutable oracle;
  
  /*///////////////////////////////////////////////////////////////
                          CONFIGURATION
  //////////////////////////////////////////////////////////////*/

  uint256 public immutable loanToValue;
  uint256 public immutable liquidationPrice;
  uint256 public immutable timeBeforeLiquidation;
  // Interest, in decimals.
  uint8 public immutable interest;

  ERC721 public immutable UNDERLYING;
  USDCVault public immutable VAULT;
  APIConsumer public immutable ORACLE;
  uint256 internal immutable BASE_UNIT;
  uint8 public immutable decimals;
  
  constructor(
    ERC721 _UNDERLYING, 
    USDCVault VAULT,
    APIConsumer ORACLE,
    uint8 _decimals,
    uint8 _interest,
    ) 
    ERC20(
      // Vault name
      string(abi.encodePacked( _UNDERLYING.name(), " Vault")),
      // Vault symbol
      string(abi.encodePacked("v", _UNDERLYING.symbol())),
      // Decimals
      _decimals
    )
    Auth(Auth(msg.sender).owner(), Auth(msg.sender).authority())
  {
     
    decimals = _decimals;

    interest = _interest;

    BASE_UNIT = 10**decimals;
    
    UNDERLYING = _UNDERLYING;

    VAULT = _VAULT;
    //Set liquidation price to be 30% of floor price.
    liquidationPrice = 0.3 * ORACLE.floorPrice; 
    //Set loan to value to be 10% of floor price.
    loanToValue = 0.1 * ORACLE.floorPrice;
  }

  /*///////////////////////////////////////////////////////////////
                              STORAGE
  //////////////////////////////////////////////////////////////*/

  struct loanData {
    // Price of token when it is liquidated.
    uint256 liquidationPrice,
    // Time when tokens can be liquidated.
    uint256 liquidationTime,
    // Amount required to unlock token (loan value + interest).
    uint256 repayAmount
  }

  // Maps token Id to loan data.
  mapping(uint256 => loanData) private getLoanData;
  
  /*///////////////////////////////////////////////////////////////
                    ERC721 BORROW/DEPOSIT LOGIC
  //////////////////////////////////////////////////////////////*/

  function borrow(ERC721 token, uint256 id, uint256 loanValue) external {

    require(token.ownerOf(id) == msg.sender, "NO_OWNERSHIP");
    require(token == UNDERLYING, "WRONG_UNDERLYING");
    require(loanValue <= loanToValue, "VALUE_EXCEEDED");

    require(USDCVault.useFunds(loanValue), "BORROW_FAILED");
    require(token.safeTransferFrom(msg.sender, this(address), id), "BORROW_FAILED");

    getLoanData[id].liquidationTime = now + timeBeforeLiquidation;
    getLoanData[id].repayAmount = loanValue * (1 + interest);
    getLoanData[id].liquidationPrice = ORACLE.floorPrice;
  }
  
  function unlock(ERC721 token, uint256 id) external payable {
    
    require(token.ownerOf(id) == msg.sender, "NO_OWNERSHIP");
    require(token == UNDERLYING, "WRONG_UNDERLYING");
    require(msg.value == getLoanData[id].repayAmount, "WRONG_MSG_VALUE");

    require(USDCVault.returnFunds(msg.value), "UNLOCK_FAILED");  
    require(token.safeTransferFrom(this(address), msg.sender, id), "UNLOCK_FAILED");
  }

  function liquidate(ERC721 token, uint256 id) external {

    require(now > getLoanData[id].liquidationTime || ORACLE.floorPrice < getLoanData[id].liquidationPrice, "LIQUIDATION_PROHIBITED");

    //TODO: Transfer to auction.
  }

  function getRepayAmount(uint256 id) public view returns(uint256) {

    require(token.ownerOf(id) == msg.sender, "NO_OWNERSHIP");
    
    return(getLoanData[id].repayAmount);
  }
}
