pragma solidity ^0.5.8;

import "./IUserRegistry.sol";

contract ChatGroupRegistry {

    struct ChatGroup {
        uint256 id;
        bytes32 adminUserName;
        bytes32 groupName;
        uint256 createdDate;
    }

    // 群ID => 群对象
    mapping(uint256 => ChatGroup) chatGroups;
    // 群ID => 群成员用户名列表
    mapping(uint256 => bytes32[]) chatMemberNames;
    // 群ID => 群成员用户名 => 群成员索引
    mapping(uint256 => mapping(bytes32 => uint256)) chatMemberIndex;
    // 用户名 => 已加入群ID列表
    mapping(bytes32 => uint256[]) userChatGroupIds;
    // 用户名 => 已加入群ID => 群ID索引
    mapping(bytes32 => mapping(uint256 => uint256)) userChatGroupIndex;

    uint256 groupId = 1;

    address public userRegistry;
    
    constructor(address _userRegistry) public {
        userRegistry = _userRegistry;
    }
    
    ///////////////
    //// Modifiers
    ///////////////

    /**
    * @notice 限群管理员调用
    * @param _groupId 群ID
    */
    modifier onlyAdmin(uint256 _groupId) {
        require(_isChatGroupExist(_groupId), "ChatGroupRegistry: current chat group not exist");
        require(_isChatGroupAdmin(_groupId), "ChatGroupRegistry: not chat group admin");
        _;
    }

    /**
    * @notice 限群成员调用
    * @param _groupId 群ID
    */
    modifier onlyMember(uint256 _groupId) {
        require(_isChatGroupExist(_groupId), "ChatGroupRegistry: current chat group not exist");
        require(_isChatGroupMember(_groupId), "ChatGroupRegistry: not chat group member");
        _;
    }
    
    ///////////////
    //// Functions
    ///////////////

    /**
     * @notice 创建聊天群
     * @dev 创建者作为管理员，自动加入群成员；每个聊天群以ID作为唯一性标识，不同群的群名称可相同
     * @param _groupName 群名称
     */
    function createChatGroup(bytes32 _groupName) external {
        require(_groupName != bytes32(0), "ChatGroupRegistry: params not be null");
        
        bytes32 _adminUserName = IUserRegistry(userRegistry).searchUserNameByAddr(msg.sender);
        ChatGroup memory chatGroup = ChatGroup({
            id: groupId,
            adminUserName: _adminUserName,
            groupName: _groupName,
            createdDate: now
        });
        chatGroups[groupId] = chatGroup;
        _addChatGroupMember(groupId, _adminUserName);
        _addUserChatGroup(_adminUserName, groupId);
        groupId++;
    }

    /**
     * @notice 邀请群成员
     * @dev 群成员可以邀请其他用户进入聊天群
     * @param _groupId 群ID
     * @param _userName 用户名
     */
    function inviteChatGroupMember(uint256 _groupId, bytes32 _userName) external onlyMember(_groupId) {
        require(IUserRegistry(userRegistry).isUserNameExist(_userName), "ChatGroupRegistry: current _userName is not exist");
        require(chatMemberIndex[_groupId][_userName] == uint256(0), "ChatGroupRegistry: current member is already exist");
        
        _addChatGroupMember(_groupId, _userName);
        _addUserChatGroup(_userName, _groupId);
    }

    /**
     * @notice 移出群成员
     * @dev 只有管理员可以强制将群用户移出聊天群
     * @param _groupId 群ID
     * @param _userName 用户名
     */
    function deleteChatGroupMember(uint256 _groupId, bytes32 _userName) external onlyAdmin(_groupId) {
        require(chatMemberIndex[_groupId][_userName] != uint256(0), "ChatGroupRegistry: current user not member");
        require(chatGroups[_groupId].adminUserName != _userName, "ChatGroupRegistry: admin can`t remove");
        
        _removeChatGroupMember(_groupId, _userName);
        _removeUserChatGroup(_userName, _groupId);
    }

    /**
     * @notice 修改群名称
     * @dev 只有管理员可以修改群名称
     * @param _groupId 群ID
     * @param _newName 新群名称
     */
    function changeChatGroupName(uint256 _groupId, bytes32 _newName) external onlyAdmin(_groupId) {
        require(_newName != bytes32(0), "ChatGroupRegistry: _newName not be null");

        chatGroups[_groupId].groupName = _newName;
    }

    /**
     * @notice 是否为群成员
     * @param _groupId 群ID
     * @return bool 是否为群成员
     */
    function isChatGroupMember(uint256 _groupId) external view returns(bool) {
        return _isChatGroupMember(_groupId);
    }

    /**
     * @notice 查询用户已加入的群ID列表
     * @return _groupIds uint256[] 群ID列表
     */
    function searchUserGroupIds() external view returns(uint256[] memory _groupIds){
        bytes32 _userName = IUserRegistry(userRegistry).searchUserNameByAddr(msg.sender);
        _groupIds = userChatGroupIds[_userName];
    }

    /**
     * @notice 查询群信息
     * @param _groupId 群ID
     * @return _id uint256 群ID
     * @return _adminUserName bytes32 管理员用户名
     * @return _groupName bytes32 群名称
     * @return _createdDate uint256 群创建时间
     * @return _memberNames bytes32[] 群成员用户名列表
     */
    function searchChatGroupInfo(uint256 _groupId) external view onlyMember(_groupId) returns(
        uint256 _id,
        bytes32 _adminUserName,
        bytes32 _groupName,
        uint256 _createdDate,
        bytes32[] memory _memberNames
    ) {
        ChatGroup memory chatGroup = chatGroups[_groupId];
        _id = chatGroup.id;
        _adminUserName = chatGroup.adminUserName;
        _groupName = chatGroup.groupName;
        _createdDate = chatGroup.createdDate;
        _memberNames = chatMemberNames[_groupId];
    }

    /**
     * @notice 添加群成员
     * @dev 内部方法
     * @param _groupId 群ID
     * @param _userName 用户名
     */
    function _addChatGroupMember(uint256 _groupId, bytes32 _userName) internal {
        chatMemberNames[_groupId].push(_userName);
        chatMemberIndex[_groupId][_userName] = chatMemberNames[_groupId].length;
    }

    /**
     * @notice 移除群成员
     * @dev 内部方法
     * @param _groupId 群ID
     * @param _userName 用户名
     */
    function _removeChatGroupMember(uint256 _groupId, bytes32 _userName) internal {
        uint256 _deleteIndex = chatMemberIndex[_groupId][_userName] - 1;
        uint256 _lastIndex = chatMemberNames[_groupId].length - 1;
        bytes32 _deleteUserName = chatMemberNames[_groupId][_deleteIndex];
        bytes32 _lastUserName = chatMemberNames[_groupId][_lastIndex];
        if(_deleteIndex != _lastIndex) {
            chatMemberNames[_groupId][_deleteIndex] = _lastUserName;
            chatMemberIndex[_groupId][_lastUserName] = _deleteIndex + 1;
        }
        delete chatMemberIndex[_groupId][_deleteUserName]; 
        chatMemberNames[_groupId].length--;
    }

    /**
     * @notice 添加用户所属群ID
     * @dev 内部方法
     * @param _userName 用户名
     * @param _groupId 群ID
     */
    function _addUserChatGroup(bytes32 _userName, uint256 _groupId) internal {
        userChatGroupIds[_userName].push(_groupId);
        userChatGroupIndex[_userName][_groupId] = userChatGroupIds[_userName].length;
    }

    /**
     * @notice 移除用户所属群ID
     * @dev 内部方法
     * @param _userName 用户名
     * @param _groupId 群ID
     */
    function _removeUserChatGroup(bytes32 _userName, uint256 _groupId) internal {
        uint256 _deleteIndex = userChatGroupIndex[_userName][_groupId] - 1;
        uint256 _lastIndex = userChatGroupIds[_userName].length - 1;
        uint256 _deleteGroupId = userChatGroupIds[_userName][_deleteIndex];
        uint256 _lastGroupId = userChatGroupIds[_userName][_lastIndex];
        if(_deleteIndex != _lastIndex) {
            userChatGroupIds[_userName][_deleteIndex] = _lastGroupId;
            userChatGroupIndex[_userName][_lastGroupId] = _deleteIndex + 1;
        }
        delete userChatGroupIndex[_userName][_deleteGroupId];
        userChatGroupIds[_userName].length--;
    }

    /**
     * @notice 群ID是否存在
     * @dev 内部方法
     * @param _groupId 群ID
     * @return bool 群ID是否存在
     */
    function _isChatGroupExist(uint256 _groupId) internal view returns(bool) {
        return _groupId != uint256(0) && _groupId < groupId;
    }

    /**
     * @notice msg.sender是否为群成员
     * @dev 内部方法
     * @param _groupId 群ID
     * @return bool msg.sender是否为群成员
     */
    function _isChatGroupMember(uint256 _groupId) internal view returns(bool) {
        bytes32 _userName = IUserRegistry(userRegistry).searchUserNameByAddr(msg.sender);
        return chatMemberIndex[_groupId][_userName] != uint256(0);
    }

    /**
     * @notice msg.sender是否为群管理员
     * @dev 内部方法
     * @param _groupId 群ID
     * @return bool msg.sender是否为群管理员
     */
    function _isChatGroupAdmin(uint256 _groupId) internal view returns(bool) {
        bytes32 _userName = IUserRegistry(userRegistry).searchUserNameByAddr(msg.sender);
        return chatGroups[_groupId].adminUserName == _userName;
    }
    

}
