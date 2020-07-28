pragma solidity ^0.4.24;

contract IChatController {
    function sendMsg(uint256 _chatGroupId, uint256 _chatOrderNum, uint256 _chatType, string _contentHash) external;
    function revertMsg(uint256 _chatGroupId, uint256 _chatOrderNum) external;
    function getMsg(uint256 _chatGroupId, uint256 _chatOrderNum) external view returns(
        uint256 _chatType,
        string memory _contentHash,
        uint256 _fromUserId,
        uint256 _createdDate
    );
}
