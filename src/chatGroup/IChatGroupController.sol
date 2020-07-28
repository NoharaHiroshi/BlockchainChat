pragma solidity ^0.4.24;

contract IChatGroupController {
    function createChatGroup(uint256 _chatGroupId, string _groupName) external;
    function inviteChatGroupMember(uint256 _chatGroupId, uint256 _userId) external;
    function deleteChatGroupMember(uint256 _chatGroupId, uint256 _userId) external;
    function changeChatGroupName(uint256 _chatGroupId,  string _newName) external;
    function changeChatGroupAdmin(uint256 _chatGroupId,  uint256 _newAdminUserId) external;
    function isChatGroupExist(uint256 _chatGroupId) external view returns(bool);
    function isChatGroupMember(uint256 _chatGroupId, uint256 _userId) public view returns(bool);
    function searchChatGroupInfo(uint256 _chatGroupId) external view returns(
        uint256 _adminUserId,
        string memory _groupName,
        uint256 _createdDate,
        uint256[] memory _memberUserIds
    );
}
