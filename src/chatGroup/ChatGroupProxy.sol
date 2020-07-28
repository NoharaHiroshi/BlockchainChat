pragma solidity ^0.4.24;

import "../library/Proxy.sol";
import "./ChatGroupStorageStateful.sol";

/**
 * 聊天群入口合约
 */
contract ChatGroupProxy is ChatGroupStorageStateful, Proxy{

    ///////////////
    //// Event
    ///////////////

    event SetStorage(address indexed operator, address indexed chatGroupStorage, address chatGroupUserRelStorage, address userStorage);

    ///////////////
    //// Functions
    ///////////////

    /**
    * @notice 设置存储
    * @dev 限链管理员调用
    * @param _chatGroupStorage 聊天群组存储合约
    * @param _chatGroupUserRelStorage 聊天群组用户关系存储合约
    * @param _userStorage 用户存储合约
    */
    function setStorage(address _chatGroupStorage, address _chatGroupUserRelStorage, address _userStorage) external onlyOwner {
        chatGroupStorage = ChatGroupStorage(_chatGroupStorage);
        chatGroupUserRelStorage = ChatGroupUserRelStorage(_chatGroupUserRelStorage);
        userStorage = UserStorage(_userStorage);
        emit SetStorage(msg.sender, _chatGroupUserRelStorage, _chatGroupUserRelStorage, _userStorage);
    }
}
