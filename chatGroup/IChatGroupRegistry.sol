pragma solidity ^0.5.8;

contract IChatGroupRegistry {
    function isChatGroupMember(uint256 _groupId) external view returns(bool);
    function isChatGroupExist(uint256 _groupId) external view returns(bool);
}
