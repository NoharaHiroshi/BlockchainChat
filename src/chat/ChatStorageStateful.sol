pragma solidity ^0.4.24;

import "./ChatStorage.sol";
import "../chatGroup/ChatGroupUserRelStorage.sol";
import "../user/UserStorage.sol";

/**
 * 信息合约需要引入的存储合约
 */
contract ChatStorageStateful {
    ChatStorage public chatStorage;
    ChatGroupUserRelStorage public chatGroupUserRelStorage;
    UserStorage public userStorage;
}
