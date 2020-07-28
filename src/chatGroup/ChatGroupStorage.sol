pragma solidity ^0.4.24;

import "../library/BaseStorage.sol";

/**
 * 聊天群存储合约
 */
contract ChatGroupStorage is BaseStorage {

    /**
    *  聊天群
    *  +---------------+---------------------+---------------------+
    *  | Field         | Type                | Desc                |
    *  +---------------+---------------------+---------------------+
    *  | id            | uint256             | 聊天群Id            |
    *  | admin_user_id | uint256             | 聊天群管理员Id      |
    *  | group_name    | string              | 聊天群名            |
    *  | created_date  | uint256             | 创建时间            |
    *  +---------------+---------------------+---------------------+
    */
    struct ChatGroup {
        uint256 id;
        uint256 adminUserId;
        string groupName;
        uint256 createdDate;
    }

    // 群Id => 群对象
    mapping(uint256 => ChatGroup) chatGroups;

    /**
    * @notice 插入数据
    * @dev 限入口合约调用
    * @dev id为主键
    * @param _chatGroupId 聊天群组Id
    * @param _adminUserId 群管理员用户Id
    * @param _groupName 聊天群名称
    * @return int 提交成功数量
    */
    function insert(
        uint256 _chatGroupId,
        uint256 _adminUserId,
        string memory _groupName
    ) public onlyProxy returns(int) {
        require(!isChatGroupExist(_chatGroupId), "ChatGroupStorage: current id has already exist");

        ChatGroup memory chatGroup = ChatGroup({
            id: _chatGroupId,
            adminUserId: _adminUserId,
            groupName: _groupName,
            createdDate: now
        });
        chatGroups[_chatGroupId] = chatGroup;

        emit InsertResult(int(1));

        return int(1);
    }

    /**
    * @notice 查询数据
    * @param _chatGroupId 聊天群组Id
    * @return _adminUserId 群管理员用户Id
    * @return _groupName 聊天群名称
    * @return _createdDate 创建时间
    */
    function select(uint256 _chatGroupId) public view returns(
        uint256 _adminUserId,
        string memory _groupName,
        uint256 _createdDate
    ){
        require(isChatGroupExist(_chatGroupId), "ChatGroupStorage: current id not exist");

        _adminUserId = chatGroups[_chatGroupId].adminUserId;
        _groupName = chatGroups[_chatGroupId].groupName;
        _createdDate = chatGroups[_chatGroupId].createdDate;
    }

    /**
    * @notice 更新数据
    * @dev 限入口合约调用
    * @param _chatGroupId 聊天群组Id
    * @param _adminUserId 群管理员用户Id
    * @param _groupName 聊天群名称
    * @return int 提交成功数量
    */
    function update(
        uint256 _chatGroupId,
        uint256 _adminUserId,
        string memory _groupName
    ) public onlyProxy returns(int) {
        require(isChatGroupExist(_chatGroupId), "ChatGroupStorage: current id not exist");

        chatGroups[_chatGroupId].id = _chatGroupId;
        chatGroups[_chatGroupId].adminUserId = _adminUserId;
        chatGroups[_chatGroupId].groupName = _groupName;

        emit UpdateResult(int(1));

        return int(1);
    }

    /**
   * @notice 删除数据
   * @dev 限入口合约调用
   * @param _chatGroupId 聊天群组Id
   * @return int 提交成功数量
   */
    function remove(uint256 _chatGroupId) public onlyProxy returns(int){
        require(isChatGroupExist(_chatGroupId), "ChatGroupStorage: current id not exist");

        delete chatGroups[_chatGroupId];

        emit RemoveResult(int(1));

        return int(1);
    }

    /**
    * @notice 群Id是否存在
    * @param _chatGroupId 群Id
    * @return bool 群Id是否存在
    */
    function isChatGroupExist(uint256 _chatGroupId) public view returns(bool) {
        return chatGroups[_chatGroupId].id != uint256(0);
    }

}
