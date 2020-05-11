pragma solidity ^0.4.24;

contract IUserController {
    function register(uint256 _userId, uint256 _phone, string _name, string _sex) external returns(int);
    function restUserAddr(uint256 _userId, address _newAddr) external returns(int);
    function changeUserPhone(uint256 _newPhone) external returns(int);
    function changeUserName(string _newName) external returns(int);
}
