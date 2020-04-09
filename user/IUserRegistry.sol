pragma solidity ^0.5.8;

interface IUserRegistry {
    function searchPhoneByAddr(address _addr) external view returns(uint256 _phone);
    function searchUserIdByPhone(uint256 _phone) external view returns(uint256 _userId);
    function isPhoneExist(bytes32 _phone) external view returns(bool);
}
