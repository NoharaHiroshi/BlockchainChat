pragma solidity ^0.4.24;

import "../user/IUserController.sol";

contract ProxyCall {

    IUserController user;

    function setUser(address _addr) public {
        user = IUserController(_addr);
    }

    function register(uint256 _userId, uint256 _phone, string _name, string _sex) external {
        user.register(_userId, _phone, _name, _sex);
    }

    function changeUserPhone(uint256 _newPhone) external {
        user.changeUserPhone(_newPhone);
    }

}
