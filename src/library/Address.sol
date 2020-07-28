pragma solidity ^0.4.25;

/**
 * 检查地址是外部账户地址还是合约地址
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
