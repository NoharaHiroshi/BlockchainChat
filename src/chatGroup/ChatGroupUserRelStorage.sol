pragma solidity ^0.4.24;

import "../library/BaseStorage.sol";

/**
 * 聊天群用户关联关系存储合约
 */
contract ChatGroupUserRelStorage is BaseStorage {

    // 聊天群 => 聊天群用户
    mapping(uint256 => uint256[]) chatGroupUsers;
    // 聊天群 => 聊天群用户 => 用户索引
    mapping(uint256 => mapping(uint256 => uint256)) chatGroupUserIndex;

    // 用户 => 用户所属聊天群
    mapping(uint256 => uint256[]) userChatGroups;
    // 用户 => 聊天群 => 聊天群索引
    mapping(uint256 => mapping(uint256 => uint256)) userChatGroupIndex;

    /**
    * @notice 插入数据
    * @dev 限入口合约调用
    * @param _chatGroupId 聊天群组Id
    * @param _userId 用户Id
    * @return int 提交成功数量
    */
    function insert(
        uint256 _chatGroupId,
        uint256 _userId
    ) public onlyProxy returns(int) {
        require(!isChatGroupMember(_chatGroupId, _userId), "ChatGroupUserRelStorage: current userId has already exist");

        chatGroupUsers[_chatGroupId].push(_userId);
        chatGroupUserIndex[_chatGroupId][_userId] = chatGroupUsers[_chatGroupId].length;

        userChatGroups[_userId].push(_chatGroupId);
        userChatGroupIndex[_userId][_chatGroupId] = userChatGroups[_userId].length;

        emit InsertResult(int(1));

        return int(1);
    }

    /**
     * @notice 查询聊天群用户
     * @param _chatGroupId 聊天群组Id
     * @return _userIds 群成员用户Id列表
     */
    function selectChatGroupUsers(uint256 _chatGroupId) public view returns(
        uint256[] memory _userIds
    ) {
        _userIds = chatGroupUsers[_chatGroupId];
    }

    /**
     * @notice 查询用户聊天群
     * @param _userId 用户Id
     * @return _chatGroupIds 聊天群Id列表
     */
    function selectUserChatGroups(uint256 _userId) public view returns(
        uint256[] memory _chatGroupIds
    ) {
        _chatGroupIds = userChatGroups[_userId];
    }

    /**
     * @notice 删除数据
     * @param _chatGroupId 聊天群组Id
     * @param _userId 成员用户Id
     * @return int 提交成功数量
     */
    function remove(uint256 _chatGroupId, uint256 _userId) public onlyProxy returns(int){
        require(isChatGroupMember(_chatGroupId, _userId), "ChatGroupUserRelStorage: current userId not exist");

        // 删除群组与用户的关联关系
        uint256 _deleteIndex = chatGroupUserIndex[_chatGroupId][_userId] - 1;
        uint256 _lastIndex = chatGroupUsers[_chatGroupId].length - 1;
        uint256 _deleteUserId = chatGroupUsers[_chatGroupId][_deleteIndex];
        uint256 _lastUserId = chatGroupUsers[_chatGroupId][_lastIndex];
        if(_deleteIndex != _lastIndex) {
            chatGroupUsers[_chatGroupId][_deleteIndex] = _lastUserId;
            chatGroupUserIndex[_chatGroupId][_lastUserId] = _deleteIndex + 1;
        }
        delete chatGroupUserIndex[_chatGroupId][_deleteUserId];
        chatGroupUsers[_chatGroupId].length--;

        // 删除用户与群组的关联关系
        uint256 deleteIndex_ = userChatGroupIndex[_userId][_chatGroupId] - 1;
        uint256 lastIndex_ = userChatGroups[_userId].length - 1;
        uint256 deleteGroupId_ = userChatGroups[_userId][deleteIndex_];
        uint256 lastGroupId_ = userChatGroups[_userId][lastIndex_];
        if(deleteIndex_ != lastIndex_) {
            userChatGroups[_userId][deleteIndex_] = lastGroupId_;
            userChatGroupIndex[_userId][lastGroupId_] = deleteIndex_ + 1;
        }
        delete userChatGroupIndex[_userId][deleteGroupId_];
        userChatGroups[_userId].length--;

        emit RemoveResult(int(1));

        return int(1);
    }

    /**
    * @notice 是否为群成员
    * @param _chatGroupId 群Id
    * @param _userId 用户Id
    * @return bool 是否为群成员
    */
    function isChatGroupMember(uint256 _chatGroupId, uint256 _userId) public view returns(bool){
        return chatGroupUserIndex[_chatGroupId][_userId] != uint256(0);
    }

}
