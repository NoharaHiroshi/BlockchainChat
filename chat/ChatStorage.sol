pragma solidity ^0.4.24;

import "../library/BaseStorage.sol";

/**
 * 聊天消息存储合约
 */
contract ChatStorage is BaseStorage {

    /**
   *  聊天消息
   *  +----------------+---------------------+-------------------------------+
   *  | Field          | Type                | Desc                          |
   *  +----------------+---------------------+-------------------------------+
   *  | chat_group_id  | uint256             | 聊天群组Id                    |
   *  | chat_order_num | uint256             | 聊天群组内信息编号            |
   *  | content_hash   | string              | 聊天内容哈希值                |
   *  | from_user_id   | uint256             | 发送方用户Id                  |
   *  | created_date   | uint256             | 发送信息时间                  |
   *  +----------------+---------------------+-------------------------------+
   */
    struct Chat {
        uint256 chatGroupId;
        uint256 chatOrderNum;
        string contentHash;
        uint256 fromUserId;
        uint256 createdDate;
    }

    // 聊天群组Id => 聊天群组内信息编号 => Chat
    mapping(uint256 => mapping(uint256 => Chat)) chats;

    /**
     * @notice 插入数据
     * @dev 限代理合约调用
     * @dev _chatGroupId与_chatOrderNum组成唯一索引
     * @param _chatGroupId 聊天群组Id
     * @param _chatOrderNum 消息编号
     * @param _contentHash 消息Hash
     * @param _fromUserId 消息发送方
     * @return int 提交成功数量
     */
    function insert(
        uint256 _chatGroupId,
        uint256 _chatOrderNum,
        string memory _contentHash,
        uint256 _fromUserId
    ) public onlyProxy returns(int) {
        // chatOrderNum递增
        require(!_isGroupNumExist(_chatGroupId, _chatOrderNum), "ChatStorage: current num has already exist");

        Chat memory chat = Chat({
            chatGroupId: _chatGroupId,
            chatOrderNum: _chatOrderNum,
            contentHash: _contentHash,
            fromUserId: _fromUserId,
            createdDate: now
        });

        chats[_chatGroupId][_chatOrderNum] = chat;

        emit InsertResult(int(1));

        return int(1);
    }

    /**
     * @notice 查询数据
     * @param _chatGroupId 聊天群组Id
     * @param _chatOrderNum 消息编号
     * @return _contentHash 消息Hash
     * @return _fromUserId 消息发送方
     * @return _createdDate 消息发送时间
     */
    function select(uint256 _chatGroupId, uint256 _chatOrderNum) public view returns(
        string memory _contentHash,
        uint256 _fromUserId,
        uint256 _createdDate
    ){
        require(_isGroupNumExist(_chatGroupId, _chatOrderNum), "ChatStorage: current num not exist");

        Chat memory chat = chats[_chatGroupId][_chatOrderNum];
        _contentHash = chat.contentHash;
        _fromUserId = chat.fromUserId;
        _createdDate = chat.createdDate;
    }

    /**
     * @notice 删除数据
     * @dev 限代理合约调用
     * @param _chatGroupId 聊天群组Id
     * @param _chatOrderNum 消息编号
     * @return int 提交成功数量
     */
    function remove(uint256 _chatGroupId, uint256 _chatOrderNum) public onlyProxy returns(int){
        require(_isGroupNumExist(_chatGroupId, _chatOrderNum), "ChatStorage: current num not exist");

        delete chats[_chatGroupId][_chatOrderNum];

        emit RemoveResult(int(1));

        return int(1);
    }

    /**
     * @notice 群组内部消息编号是否已存在
     * @param _chatGroupId 聊天群组Id
     * @param _chatOrderNum 消息编号
     * @return bool 是否存在
     */
    function _isGroupNumExist(uint256 _chatGroupId, uint256 _chatOrderNum) internal view returns(bool) {
        return chats[_chatGroupId][_chatOrderNum].fromUserId != uint256(0);
    }

}
