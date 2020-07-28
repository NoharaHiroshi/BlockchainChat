pragma solidity ^0.4.24;

import "../library/Ownable.sol";
import "./UserStorageStateful.sol";

/**
 * 用户逻辑合约
 */
contract UserController is UserStorageStateful, Ownable {

    ///////////////
    //// Event
    ///////////////

    event Register(uint256 indexed userId, uint256 indexed phone, string indexed name, string sex);
    event RestUserAddr(uint256 indexed userId, address indexed newAddr);
    event ChangeUserPhone(uint256 indexed userId, uint256 indexed rawPhone, uint256 indexed newPhone);

    ///////////////
    //// Functions
    ///////////////

    /**
     * @notice 注册用户
     * @dev 链外系统负责对用户手机号、姓名进行核验，为防止信息在联盟链的泄露，其他个人信息链下保存。
     * @dev 链下系统分配的userId全局唯一，msg.sender作为User的addr，phone、addr全局唯一，不同User的name可相同。
     * @param _userId 用户id
     * @param _phone 手机号
     * @param _name 姓名
     * @param _sex 性别
     */
    function register(uint256 _userId, uint256 _phone, string _name, string _sex) external {
        require(userStorage.insert(_userId, _phone, _name, _sex, msg.sender) == int(1), "UserController: insert user error");

        emit Register(_userId, _phone, _name, _sex);
    }

    /**
     * @notice 重置用户地址
     * @dev 该方法由链管理员调用
     * @dev 当user.addr对应的私钥丢失时，可输入注册时链下系统分配的userId和新外部账户地址。
     * @dev 链下系统将查询用户信息，并向注册时的手机号发送验证码，通过验证后，链管理员用新外部账户地址替换原有addr。
     * @param _userId 用户Id
     * @param _newAddr 新外部账户地址
     */
    function restUserAddr(uint256 _userId, address _newAddr) external onlyOwner {
        (, uint256 _phone, string memory _name, string memory _sex, , ) = userStorage.select(_userId);
        require(userStorage.update(_userId, _phone, _name, _sex, _newAddr) == int(1), "UserController: update user error");

        emit RestUserAddr(_userId, _newAddr);
    }

    /**
     * @notice 修改用户手机号
     * @dev 链外对_newPhone发送验证码进行验证，确保_newPhone的所有权。
     * @dev 链内调用该方法，会通过msg.sender查询到当前user，并修改当前user的手机号
     * @param _newPhone 新手机号
     */
    function changeUserPhone(uint256 _newPhone) external {
        (uint256 _userId, uint256 _rawPhone, string memory _name, string memory _sex, address _addr, ) = userStorage.selectByAddr(msg.sender);
        require(userStorage.update(_userId, _newPhone, _name, _sex, _addr) == int(1), "UserController: update user error");

        emit ChangeUserPhone(_userId, _rawPhone, _newPhone);
    }
    
    /**
     * @notice 修改用户名 
     * @param _newName 新用户名
     */
    function changeUserName(string _newName) external {
        (uint256 _userId, uint256 _phone, , string memory _sex, address _addr, ) = userStorage.selectByAddr(msg.sender);
        require(userStorage.update(_userId, _phone, _newName, _sex, _addr) == int(1), "UserController: update user error");
    }

}
