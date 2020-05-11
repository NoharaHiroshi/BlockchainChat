pragma solidity ^0.4.24;

import "../library/Proxy.sol";
import "./UserStorageStateful.sol";

/**
 * 用户代理合约
 */
contract UserProxy is UserStorageStateful, Proxy {

    ///////////////
    //// Event
    ///////////////

    event SetStorage(address indexed operator, address indexed userStorage);

    ///////////////
    //// Functions
    ///////////////

    /**
    * @notice 设置存储
    * @dev 限链管理员调用
    * @param _storageAddr 用户存储合约
    */
    function setStorage(address _storageAddr) external onlyOwner {
        userStorage = UserStorage(_storageAddr);
        emit SetStorage(msg.sender, _storageAddr);
    }
}
