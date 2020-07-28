pragma solidity ^0.4.24;

import "./UserStorage.sol";

/**
 * 用户合约需要引入的存储合约
 */
contract UserStorageStateful {
    UserStorage public userStorage;
}