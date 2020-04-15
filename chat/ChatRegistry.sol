pragma solidity ^0.5.8;

import "../user/IUserRegistry.sol";
import "../chatGroup/IChatGroupRegistry.sol";

contract ChatRegistry {

    struct Message {
        uint256 id;                 // 消息Id
        bytes32 contentHash;        // 消息Hash
        uint256 fromUserId;         // 发送方userId
        uint256 blockTimestamp;     // 发送块时间
    }

    // id => Message
    mapping(uint256 => Message) messages;
    // userId => id[]
    mapping(uint256 => uint256[]) userSendMessages;

    uint256 messageId = 1;
    uint256 public chatGroupId;
    
    IUserRegistry public userRegistry;
    IChatGroupRegistry public chatGroupRegistry;

    ///////////////
    //// Event
    ///////////////
    
    event SendMsg(uint256 indexed messageId, uint256 indexed fromUserId);

    ///////////////
    //// Modifier
    ///////////////
    
    modifier onlyMember() {
        uint256 _userId = userRegistry.searchUserIdByAddr(msg.sender);
        require(chatGroupRegistry.isChatGroupMember(_userId, chatGroupId), "ChatRegistry: current user is not chatGroup member");
        _;
    }

    ///////////////
    //// Functions
    ///////////////

    constructor(uint256 _chatGroupId, address _userRegistry, address _chatGroupRegistry) public {
        chatGroupId = _chatGroupId;
        userRegistry = IUserRegistry(_userRegistry);
        chatGroupRegistry = IChatGroupRegistry(_chatGroupRegistry);
    }

    /**
     * @notice 发送信息
     * @dev 机构成员可发送信息
     * @param _contentHash 信息hash
     */
    function sendMsg(bytes32 _contentHash) external onlyMember {
        require(_contentHash.length != uint256(0), "ChatRegistry: not allow null message");
        uint256 _userId = userRegistry.searchUserIdByAddr(msg.sender);
        require(chatGroupRegistry.isChatGroupMember(_userId, chatGroupId), "ChatRegistry: current user is not chatGroup member");

        Message memory message = Message({
            id: messageId,
            contentHash: _contentHash,
            fromUserId: _userId,
            blockTimestamp: now
        });
        messages[messageId] = message;
        userSendMessages[_userId].push(messageId);
        emit SendMsg(messageId, _userId);
        messageId++;
    }

    /**
    * @notice 获取当前最新信息ID
    * @dev 机构成员可获取
    * @return _messageId 信息Id
    */
    function getLastMsgId() external view onlyMember returns(
        uint256 _messageId
    ) {
        _messageId = messageId - 1;
    }

    /**
    * @notice 批量获取信息
    * @dev 从_messageId起，向前读取_count条信息，_messageId类比offset，_count类比limit
    * @dev 例：第一条信息，数据来源_ids[0],_contentHash[0],_fromUserIds[0],_blockTimestamps[0]
    * @dev 机构成员可发送信息, 最多可以一次性获取10条信息，防止out of gas
    * @param _messageId 信息Id
    * @param _count 获取数量
    * @return _len 返回的消息长度
    * @return _ids 返回消息Id列表
    * @return _contentHashes 返回消息hash列表
    * @return _fromUserIds 返回消息发送者userId列表
    * @return _blockTimestamps 返回消息发送时间列表
    */
    function getMsgs(uint256 _messageId, uint256 _count) external view onlyMember returns(
        uint256 _len,
        uint256[] memory _ids,
        bytes32[] memory _contentHashes,
        uint256[] memory _fromUserIds,
        uint256[] memory _blockTimestamps
    ) {
        require(_isMsgExist(_messageId), "ChatRegistry: current message not exist");
        require(_count != uint256(0) && _count <= uint256(10), "ChatRegistry: _count not be zero and must be less then 10");
        uint256 c;
        if(_messageId < _count) {
            c = _messageId;     
        } else {
            c = _count; 
        }
        uint256 i;
        _len = 0;
        _ids = new uint256[](c);
        _contentHashes = new bytes32[](c);
        _fromUserIds = new uint256[](c);
        _blockTimestamps = new uint256[](c);
        for(i=_messageId; i>_messageId-c; i--) {
            Message memory message = messages[i];
            _ids[_len] = i;
            _contentHashes[_len] = message.contentHash;
            _fromUserIds[_len] = message.fromUserId;
            _blockTimestamps[_len] = message.blockTimestamp;
            _len++;
        }
        return (c, _ids, _contentHashes, _fromUserIds, _blockTimestamps);
    }

    /**
    * @notice 获取信息
    * @dev 获取指定_messageId信息
    * @param _messageId 信息Id
    * @return _id 返回消息Id
    * @return _contentHash 返回消息hash
    * @return _fromUserId 返回消息发送者userId
    * @return _blockTimestamp 返回消息发送时间
    */
    function getMsg(uint256 _messageId) external view onlyMember returns(
        uint256 _id,
        bytes32 _contentHash,
        uint256 _fromUserId,
        uint256 _blockTimestamp
    ) {
        require(_isMsgExist(_messageId), "ChatRegistry: current message not exist");
        
        Message memory message = messages[_messageId];
        _id = _messageId;
        _contentHash = message.contentHash;
        _fromUserId = message.fromUserId;
        _blockTimestamp = message.blockTimestamp;
    }
    
    function _isMsgExist(uint256 _messageId) internal view returns(bool) {
        return _messageId != uint256(0) && _messageId < messageId;
    }
}
