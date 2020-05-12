pragma solidity ^0.4.24;

import "../library/Ownable.sol";
import "./ChatStorageStateful.sol";

/**
 * 信息逻辑合约
 */
contract ChatController is ChatStorageStateful, Ownable {

    ///////////////
    //// Event
    ///////////////

    event SendMsg(uint256 indexed chatGroupId, uint256 indexed fromUserId);
    event RevertMsg(uint256 indexed chatGroupId, uint256 indexed chetOrderNum, uint256 indexed fromUserId);

    ///////////////
    //// Modifiers
    ///////////////

    /**
    * @notice 限群成员调用
    * @param _chatGroupId 群Id
    */
    modifier onlyMember(uint256 _chatGroupId) {
        (uint256 _operatorId, , , , , ) = userStorage.selectByAddr(msg.sender);
        require(chatGroupUserRelStorage.isChatGroupMember(_chatGroupId, _operatorId), "ChatController: only chat group member call");
        _;
    }

    /**
    * @notice 限发送信息者调用
    * @param _chatGroupId 群Id
    * @param _chatOrderNum 信息编号
    */
    modifier onlySelf(uint256 _chatGroupId, uint256 _chatOrderNum) {
        (uint256 _operatorId, , , , , ) = userStorage.selectByAddr(msg.sender);
        (, uint256 _fromUserId, ) = chatStorage.select(_chatGroupId, _chatOrderNum);
        require(_operatorId == _fromUserId, "ChatController: only send msg self call");
        _;
    }

    ///////////////
    //// Functions
    ///////////////

    /**
     * @notice 发送信息
     * @dev 限群组成员发送信息
     * @param _chatGroupId 群组Id
     * @param _chatOrderNum 信息编号
     * @param _contentHash 信息hash
     */
    function sendMsg(uint256 _chatGroupId, uint256 _chatOrderNum, string _contentHash) external onlyMember(_chatGroupId) {
        (uint256 _fromUserId, , , , , ) = userStorage.selectByAddr(msg.sender);

        require(chatStorage.insert(_chatGroupId, _chatOrderNum, _contentHash, _fromUserId) == int(1), "ChatController: insert msg error");
        emit SendMsg(_chatGroupId, _fromUserId);
    }

    /**
     * @notice 撤回信息
     * @dev 发送信息者可撤回，且只能撤回5分钟以内发送的信息
     * @param _chatGroupId 群组Id
     * @param _chatOrderNum 信息编号
     */
    function revertMsg(uint256 _chatGroupId, uint256 _chatOrderNum) external onlySelf(_chatGroupId, _chatOrderNum) {
        (, uint256 _fromUserId, uint256 _createdDate) = chatStorage.select(_chatGroupId, _chatOrderNum);
        require(now <= _createdDate + uint256(5) * uint256(1000) * 1 minutes, "ChatController: only revert msg within 5 minutes");
        require(chatStorage.remove(_chatGroupId, _chatOrderNum) == int(1), "ChatController: remove msg error");

        emit RevertMsg(_chatGroupId, _chatOrderNum, _fromUserId);
    }

    /**
    * @notice 获取信息
    * @dev 获取聊天群组指定编号信息
    * @param _chatGroupId 聊天群组Id
    * @param _chatOrderNum 信息编号
    * @return _contentHash 返回消息hash
    * @return _fromUserId 返回消息发送者userId
    * @return _createdDate 返回消息发送时间
    */
    function getMsg(uint256 _chatGroupId, uint256 _chatOrderNum) external view returns(
        string memory _contentHash,
        uint256 _fromUserId,
        uint256 _createdDate
    ) {
        (_contentHash, _fromUserId, _createdDate) = chatStorage.select(_chatGroupId, _chatOrderNum);
    }


}
