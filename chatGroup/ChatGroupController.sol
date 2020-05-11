pragma solidity ^0.4.24;

import "../library/Ownable.sol";
import "./ChatGroupStorageStateful.sol";

/**
 * 聊天群逻辑合约
 */
contract ChatGroupController is ChatGroupStorageStateful, Ownable {

    ///////////////
    //// Events
    ///////////////
    event CreateChatGroup(uint256 indexed chatGroupId, uint256 indexed adminUserId, string indexed groupName);
    event InviteChatGroupMember(uint256 indexed chatGroupId, uint256 indexed userId);
    event DeleteChatGroupMember(uint256 indexed chatGroupId, uint256 indexed userId);
    event ChangeChatGroupName(uint256 indexed chatGroupId,  string indexed newName);
    event ChangeChatGroupAdmin(uint256 indexed chatGroupId,  uint256 indexed userId);

    ///////////////
    //// Modifiers
    ///////////////

    /**
    * @notice 限群管理员调用
    * @param _chatGroupId 群Id
    */
    modifier onlyAdmin(uint256 _chatGroupId) {
        (uint256 _operatorId, , , , , ) = userStorage.selectByAddr(msg.sender);
        (uint256 _adminUserId, , ) = chatGroupStorage.select(_chatGroupId);
        require(_operatorId == _adminUserId, "chatGroupController: only chat group admin call");
        _;
    }

    /**
    * @notice 限群成员调用
    * @param _chatGroupId 群Id
    */
    modifier onlyMember(uint256 _chatGroupId) {
        (uint256 _operatorId, , , , , ) = userStorage.selectByAddr(msg.sender);
        require(chatGroupUserRelStorage.isChatGroupMember(_chatGroupId, _operatorId), "chatGroupController: only chat group member call");
        _;
    }

    ///////////////
    //// Functions
    ///////////////

    /**
     * @notice 创建聊天群
     * @dev 创建者作为管理员，自动加入群成员；每个聊天群以Id作为唯一性标识，不同群的群名称可相同
     * @param _chatGroupId 群Id
     * @param _groupName 群名称
     */
    function createChatGroup(
        uint256 _chatGroupId,
        string _groupName
    ) external {
        (uint256 _adminUserId, , , , , ) = userStorage.selectByAddr(msg.sender);

        require(chatGroupStorage.insert(_chatGroupId, _adminUserId, _groupName) == int(1), "chatGroupController: create chat group error");
        require(chatGroupUserRelStorage.insert(_chatGroupId, _adminUserId) == int(1), "chatGroupController: add chat group admin error");

        emit CreateChatGroup(_chatGroupId, _adminUserId, _groupName);
    }

    /**
     * @notice 邀请群成员
     * @dev 群成员可以邀请其他用户进入聊天群
     * @param _chatGroupId 群Id
     * @param _userId 用户Id
     */
    function inviteChatGroupMember(uint256 _chatGroupId, uint256 _userId) external onlyMember(_chatGroupId) {
        require(chatGroupUserRelStorage.insert(_chatGroupId, _userId) == int(1), "chatGroupController: add chat group admin error");

        emit InviteChatGroupMember(_chatGroupId, _userId);
    }

    /**
     * @notice 移出群成员
     * @dev 只有管理员可以强制将群用户移出聊天群
     * @dev 管理员不可从聊天群中移除自己，如果要退群，需要先将群管理权限移交给其他成员
     * @param _chatGroupId 群Id
     * @param _userId 用户Id
     */
    function deleteChatGroupMember(uint256 _chatGroupId, uint256 _userId) external onlyAdmin(_chatGroupId) {
        (uint256 _adminUserId, , ) = chatGroupStorage.select(_chatGroupId);

        require(_userId != _adminUserId, "chatGroupController: chat group admin can`t delete");
        require(chatGroupUserRelStorage.remove(_chatGroupId, _userId) == int(1), "chatGroupController: remove chat group member error");

        emit DeleteChatGroupMember(_chatGroupId, _userId);
    }

    /**
     * @notice 修改群名称
     * @dev 只有管理员可以修改群名称
     * @param _chatGroupId 群Id
     * @param _newName 新群名称
     */
    function changeChatGroupName(uint256 _chatGroupId,  string _newName) external onlyAdmin(_chatGroupId) {
        (uint256 _adminUserId, ,) = chatGroupStorage.select(_chatGroupId);
        require(chatGroupStorage.update(_chatGroupId, _adminUserId, _newName) == int(1), "chatGroupController: update chat group name error");

        emit ChangeChatGroupName(_chatGroupId, _newName);
    }

    /**
     * @notice 移交群管理员
     * @dev 限管理员调用
     * @param _chatGroupId 群Id
     * @param _newAdminUserId 新群管理员用户Id
     */
    function changeChatGroupAdmin(uint256 _chatGroupId,  uint256 _newAdminUserId) external onlyAdmin(_chatGroupId) {
        (, string memory _groupName,) = chatGroupStorage.select(_chatGroupId);
        require(chatGroupStorage.update(_chatGroupId, _newAdminUserId, _groupName) == int(1), "chatGroupController: update chat group name error");
        
        emit ChangeChatGroupAdmin(_chatGroupId, _newAdminUserId);
    }

    /**
     * @notice 群Id是否存在
     * @param _chatGroupId 群Id
     * @return bool 群Id是否存在
     */
    function isChatGroupExist(uint256 _chatGroupId) external view returns(bool) {
        return chatGroupStorage.isChatGroupExist(_chatGroupId);
    }

    /**
     * @notice 是否为群成员
     * @param _chatGroupId 群Id
     * @return bool 是否为群成员
     */
    function isChatGroupMember(uint256 _chatGroupId, uint256 _userId) public view returns(bool) {
        return chatGroupUserRelStorage.isChatGroupMember(_chatGroupId, _userId);
    }

    /**
     * @notice 查询群信息
     * @param _chatGroupId 群Id
     * @return _adminUserId 管理员用户Id
     * @return _groupName 群名称
     * @return _createdDate 群创建时间
     * @return _memberNames 群成员用户Id列表
     */
    function searchChatGroupInfo(uint256 _chatGroupId) external view returns(
        uint256 _adminUserId,
        string memory _groupName,
        uint256 _createdDate,
        uint256[] memory _memberUserIds
    ) {
        (_adminUserId, _groupName,  _createdDate) = chatGroupStorage.select(_chatGroupId);
        _memberUserIds = chatGroupUserRelStorage.selectChatGroupUsers(_chatGroupId);
    }
}
