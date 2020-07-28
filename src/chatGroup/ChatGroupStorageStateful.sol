pragma solidity ^0.4.24;

import "../user/UserStorage.sol";
import "./ChatGroupStorage.sol";
import "./ChatGroupUserRelStorage.sol";

/**
 * 聊天群合约引入的存储合约
 */
contract ChatGroupStorageStateful {
    ChatGroupStorage public chatGroupStorage;
    ChatGroupUserRelStorage public chatGroupUserRelStorage;
    UserStorage public userStorage;
}
