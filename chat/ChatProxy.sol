pragma solidity ^0.4.24;

import "../library/Proxy.sol";
import "./ChatStorageStateful.sol";

/**
 * 信息代理合约
 */
contract ChatProxy is ChatStorageStateful, Proxy {

    ///////////////
    //// Event
    ///////////////
    event SetStorage(address indexed operator, address indexed chatStorage, address chatGroupUserRelStorage, address userStorage);

    ///////////////
    //// Functions
    ///////////////

    /**
    * @notice 设置存储
    * @dev 限链管理员调用
    * @param _chatStorage 消息存储合约
    * @param _chatGroupUserRelStorage 聊天群组用户关系存储合约
    * @param _userStorage 用户存储合约
    */
    function setStorage(address _chatStorage, address _chatGroupUserRelStorage, address _userStorage) external onlyOwner {
        chatStorage = ChatStorage(_chatStorage);
        chatGroupUserRelStorage = ChatGroupUserRelStorage(_chatGroupUserRelStorage);
        userStorage = UserStorage(_userStorage);
        emit SetStorage(msg.sender, _chatStorage, _chatGroupUserRelStorage, _userStorage);
    }
}
