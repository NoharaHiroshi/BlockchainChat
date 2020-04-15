pragma solidity ^0.5.8;

import "../user/IUserRegistry.sol";
import "../chat/ChatRegistry.sol";

contract ChatGroupRegistry {

    struct ChatGroup {
        uint256 id;
        uint256 adminUserId;
        string groupName;
        address chatAddr;
        uint256 createdDate;
    }

    // 群Id => 群对象
    mapping(uint256 => ChatGroup) chatGroups;
    // 群Id => 群成员userId列表
    mapping(uint256 => uint256[]) chatMemberUserIds;
    // 群Id => 群成员userId => 群成员索引
    mapping(uint256 => mapping(uint256 => uint256)) chatMemberIndex;
    // 用户userId => 已加入群Id列表
    mapping(uint256 => uint256[]) userChatGroupIds;
    // 用户userId => 已加入群Id => 群Id索引
    mapping(uint256 => mapping(uint256 => uint256)) userChatGroupIndex;

    uint256 groupId = 1;

    IUserRegistry public userRegistry;
    
    constructor(address _userRegistry) public {
        userRegistry = IUserRegistry(_userRegistry);
    }
    
    ///////////////
    //// Modifiers
    ///////////////

    /**
    * @notice 限群管理员调用
    * @param _groupId 群Id
    */
    modifier onlyAdmin(uint256 _groupId) {
        uint256 _userId = userRegistry.searchUserIdByAddr(msg.sender);
        require(_isChatGroupExist(_groupId), "ChatGroupRegistry: current chat group not exist");
        require(_isChatGroupAdmin(_userId, _groupId), "ChatGroupRegistry: not chat group admin");
        _;
    }

    /**
    * @notice 限群成员调用
    * @param _groupId 群Id
    */
    modifier onlyMember(uint256 _groupId) {
        uint256 _userId = userRegistry.searchUserIdByAddr(msg.sender);
        require(_isChatGroupExist(_groupId), "ChatGroupRegistry: current chat group not exist");
        require(_isChatGroupMember(_userId, _groupId), "ChatGroupRegistry: not chat group member");
        _;
    }
    
    ///////////////
    //// Functions
    ///////////////

    /**
     * @notice 创建聊天群
     * @dev 创建者作为管理员，自动加入群成员；每个聊天群以Id作为唯一性标识，不同群的群名称可相同
     * @param _groupName 群名称
     */
    function createChatGroup(string calldata _groupName) external {
        require(bytes(_groupName).length != uint256(0), "ChatGroupRegistry: params not be null");
        
        uint256 _adminUserId = userRegistry.searchUserIdByAddr(msg.sender);
        ChatRegistry chat = new ChatRegistry(groupId, address(userRegistry), address(this));
        ChatGroup memory chatGroup = ChatGroup({
            id: groupId,
            adminUserId: _adminUserId,
            groupName: _groupName,
            chatAddr: address(chat),
            createdDate: now
        });
        chatGroups[groupId] = chatGroup;
        _addChatGroupMember(groupId, _adminUserId);
        _recordUserChatGroup(_adminUserId, groupId);
        groupId++;
    }

    /**
     * @notice 邀请群成员
     * @dev 群成员可以邀请其他用户进入聊天群
     * @param _groupId 群Id 
     * @param _userId 用户Id 
     */
    function inviteChatGroupMember(uint256 _groupId, uint256 _userId) external onlyMember(_groupId) {
        require(userRegistry.isUserExist(_userId), "ChatGroupRegistry: current _userId is not exist");
        require(chatMemberIndex[_groupId][_userId] == uint256(0), "ChatGroupRegistry: current member is already exist");
        
        _addChatGroupMember(_groupId, _userId);
        _recordUserChatGroup(_userId, _groupId);
    }

    /**
     * @notice 移出群成员
     * @dev 只有管理员可以强制将群用户移出聊天群
     * @param _groupId 群Id
     * @param _userId 用户Id 
     */
    function deleteChatGroupMember(uint256 _groupId, uint256 _userId) external onlyAdmin(_groupId) {
        require(chatMemberIndex[_groupId][_userId] != uint256(0), "ChatGroupRegistry: current user not member");
        require(chatGroups[_groupId].adminUserId != _userId, "ChatGroupRegistry: admin can`t remove");
        
        _removeChatGroupMember(_groupId, _userId);
        _removeUserChatGroup(_userId, _groupId);
    }

    /**
     * @notice 修改群名称
     * @dev 只有管理员可以修改群名称
     * @param _groupId 群Id
     * @param _newName 新群名称
     */
    function changeChatGroupName(uint256 _groupId, string calldata _newName) external onlyAdmin(_groupId) {
        require(bytes(_newName).length != uint256(0), "ChatGroupRegistry: _newName not be null");

        chatGroups[_groupId].groupName = _newName;
    }
    
    /**
     * @notice 群Id是否存在
     * @param _groupId 群Id
     * @return bool 群Id是否存在
     */
    function isChatGroupExist(uint256 _groupId) external view returns(bool) {
        return _isChatGroupExist(_groupId);
    }

    /**
     * @notice 是否为群成员
     * @param _groupId 群Id
     * @return bool 是否为群成员
     */
    function isChatGroupMember(uint256 _userId, uint256 _groupId) external view returns(bool) {
        return _isChatGroupMember(_userId, _groupId);
    }
    
     /**
     * @notice msg.sender是否为群管理员
     * @param _groupId 群Id
     * @return bool msg.sender是否为群管理员
     */
    function isChatGroupAdmin(uint256 _userId, uint256 _groupId) external view returns(bool) {
        return _isChatGroupAdmin(_userId, _groupId);
    }

    /**
     * @notice 查询用户已加入的群Id列表
     * @return _groupIds uint256[] 群Id列表
     */
    function searchUserGroupIds() external view returns(uint256[] memory _groupIds){
        uint256 _userId = userRegistry.searchUserIdByAddr(msg.sender);
        _groupIds = userChatGroupIds[_userId];
    }

    /**
     * @notice 查询群信息
     * @param _groupId 群Id
     * @return _id uint256 群Id
     * @return _adminUserId uint256 管理员用户Id
     * @return _groupName string 群名称
     * @return _chatAddr address 群合约地址 
     * @return _createdDate uint256 群创建时间
     * @return _memberNames uint256[] 群成员用户Id列表
     */
    function searchChatGroupInfo(uint256 _groupId) external view onlyMember(_groupId) returns(
        uint256 _id,
        uint256 _adminUserId,
        string memory _groupName,
        uint256 _createdDate,
        address _chatAddr,
        uint256[] memory _memberUserIds
    ) {
        ChatGroup memory chatGroup = chatGroups[_groupId];
        _id = chatGroup.id;
        _adminUserId = chatGroup.adminUserId;
        _groupName = chatGroup.groupName;
        _createdDate = chatGroup.createdDate;
        _chatAddr = chatGroup.chatAddr;
        _memberUserIds = chatMemberUserIds[_groupId];
    }

    /**
     * @notice 添加群成员
     * @dev 内部方法
     * @param _groupId 群Id
     * @param _userId 用户名
     */
    function _addChatGroupMember(uint256 _groupId, uint256 _userId) internal {
        chatMemberUserIds[_groupId].push(_userId);
        chatMemberIndex[_groupId][_userId] = chatMemberUserIds[_groupId].length;
    }

    /**
     * @notice 移除群成员
     * @dev 内部方法
     * @param _groupId 群Id
     * @param _userId 用户Id 
     */
    function _removeChatGroupMember(uint256 _groupId, uint256 _userId) internal {
        uint256 _deleteIndex = chatMemberIndex[_groupId][_userId] - 1;
        uint256 _lastIndex = chatMemberUserIds[_groupId].length - 1;
        uint256 _deleteUserId = chatMemberUserIds[_groupId][_deleteIndex];
        uint256 _lastUserId = chatMemberUserIds[_groupId][_lastIndex];
        if(_deleteIndex != _lastIndex) {
            chatMemberUserIds[_groupId][_deleteIndex] = _lastUserId;
            chatMemberIndex[_groupId][_lastUserId] = _deleteIndex + 1;
        }
        delete chatMemberIndex[_groupId][_deleteUserId]; 
        chatMemberUserIds[_groupId].length--;
    }

    /**
     * @notice 记录用户所属群Id
     * @dev 内部方法
     * @param _userId 用户名
     * @param _groupId 群Id
     */
    function _recordUserChatGroup(uint256 _userId, uint256 _groupId) internal {
        userChatGroupIds[_userId].push(_groupId);
        userChatGroupIndex[_userId][_groupId] = userChatGroupIds[_userId].length;
    }

    /**
     * @notice 移除用户所属群Id
     * @dev 内部方法
     * @param _userId 用户名
     * @param _groupId 群Id
     */
    function _removeUserChatGroup(uint256 _userId, uint256 _groupId) internal {
        uint256 _deleteIndex = userChatGroupIndex[_userId][_groupId] - 1;
        uint256 _lastIndex = userChatGroupIds[_userId].length - 1;
        uint256 _deleteGroupId = userChatGroupIds[_userId][_deleteIndex];
        uint256 _lastGroupId = userChatGroupIds[_userId][_lastIndex];
        if(_deleteIndex != _lastIndex) {
            userChatGroupIds[_userId][_deleteIndex] = _lastGroupId;
            userChatGroupIndex[_userId][_lastGroupId] = _deleteIndex + 1;
        }
        delete userChatGroupIndex[_userId][_deleteGroupId];
        userChatGroupIds[_userId].length--;
    }

    /**
     * @notice 群Id是否存在
     * @dev 内部方法
     * @param _groupId 群Id
     * @return bool 群Id是否存在
     */
    function _isChatGroupExist(uint256 _groupId) internal view returns(bool) {
        return _groupId != uint256(0) && _groupId < groupId;
    }

    /**
     * @notice msg.sender是否为群成员
     * @dev 内部方法
     * @param _groupId 群Id
     * @return bool msg.sender是否为群成员
     */
    function _isChatGroupMember(uint256 _userId, uint256 _groupId) internal view returns(bool) {
        return chatMemberIndex[_groupId][_userId] != uint256(0);
    }

    /**
     * @notice msg.sender是否为群管理员
     * @dev 内部方法
     * @param _groupId 群Id
     * @return bool msg.sender是否为群管理员
     */
    function _isChatGroupAdmin(uint256 _userId, uint256 _groupId) internal view returns(bool) {
        return chatGroups[_groupId].adminUserId == _userId;
    }
    

}
