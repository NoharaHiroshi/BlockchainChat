pragma solidity ^0.5.8;

import "../user/IUserRegistry.sol";
import "../chatGroup/IChatGroupRegistry.sol";

contract ChatRegistry {

    struct Message {
        uint256 id;
        bytes32 contentHash;
        uint256 fromUserId;
        uint256 blockTimestamp;
    }

    mapping(uint256 => Message) messages;
    mapping(uint256 => uint256[]) userSendMessages;

    uint256 messageId = 1;
    uint256 public chatGroupId;
    
    IUserRegistry public userRegistry;
    IChatGroupRegistry public chatGroupRegistry;
    
    event SendMsg(uint256 indexed messageId, uint256 indexed fromUserId);
    
    modifier onlyMember() {
        uint256 _userId = userRegistry.searchUserIdByAddr(msg.sender);
        require(chatGroupRegistry.isChatGroupMember(_userId, chatGroupId), "ChatRegistry: current user is not chatGroup member");
        _;
    }

    constructor(uint256 _chatGroupId, address _userRegistry, address _chatGroupRegistry) public {
        chatGroupId = _chatGroupId;
        userRegistry = IUserRegistry(_userRegistry);
        chatGroupRegistry = IChatGroupRegistry(_chatGroupRegistry);
    }

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
    
    function getLastMsgId() external view onlyMember returns(
        uint256 _messageId
    ) {
        _messageId = messageId - 1;
    }
    
    function getMsgs(uint256 _messageId, uint256 _count) external view onlyMember returns(
        uint256,
        uint256[] memory _ids,
        bytes32[] memory _contentHashs,
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
        uint256 len = 0;
        _ids = new uint256[](c);
        _contentHashs = new bytes32[](c);
        _fromUserIds = new uint256[](c);
        _blockTimestamps = new uint256[](c);
        for(i=_messageId; i>_messageId-c; i--) {
            Message memory message = messages[i];
            _ids[len] = i;
            _contentHashs[len] = message.contentHash;
            _fromUserIds[len] = message.fromUserId;
            _blockTimestamps[len] = message.blockTimestamp;
            len++;
        }
        return (c, _ids, _contentHashs, _fromUserIds, _blockTimestamps);
    }
    
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
