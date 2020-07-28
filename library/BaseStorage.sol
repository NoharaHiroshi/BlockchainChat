pragma solidity ^0.4.24;

import "./Ownable.sol";

/**
 * 父存储合约
 */
contract BaseStorage is Ownable {

    // 入口地址
    address public proxyAddress;

    ///////////////
    //// Event
    ///////////////

    event CreateResult(int count);
    event InsertResult(int count);
    event UpdateResult(int count);
    event RemoveResult(int count);
    event SetProxy(address indexed operator, address indexed proxy);

    ///////////////
    //// Modifier
    ///////////////

    // 仅限入口合约调用
    modifier onlyProxy() {
        require(msg.sender == proxyAddress, "BaseStorage: only proxy can call");
        _;
    }

    ///////////////
    //// Functions
    ///////////////

    // 设置入口
    function setProxy(address _proxy) external onlyOwner {
        proxyAddress = _proxy;
        emit SetProxy(msg.sender, _proxy);
    }

}
