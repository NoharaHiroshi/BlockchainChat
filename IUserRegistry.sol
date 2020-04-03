pragma solidity ^0.5.8;

interface IUserRegistry {
    function searchUserNameByAddr(address _addr) external view returns(bytes32 _userName);
    function isUserNameExist(bytes32 _userName) external view returns(bool);
}
