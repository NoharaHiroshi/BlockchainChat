pragma solidity ^0.5.8;

import "../Ownable.sol";

contract UserRegistry is Ownable {
    struct User {
        uint256 phone;
        bytes32 nickName;
        address addr;
    }

    mapping(uint256 => User) users;
    // owner => phone
    mapping(address => uint256) userPhones;

    ///////////////
    //// Functions
    ///////////////

    /**
     * @notice 注册用户
     * @dev msg.sender作为User的addr，User以phone作为唯一性标识。不同User的nickName可相同
     * @param _phone 手机号
     * @param _nickName 昵称
     */
    function register(uint256 _phone, bytes32 _nickName) external {
        require(_phone != uint256(0) && _nickName != bytes32(0), "UserRegistry: params not be null");
        require(!_isAddrRegistered(msg.sender), "UserRegistry: current address has already register");
        require(!_isPhoneExist(_phone), "UserRegistry: current phone has already exist");

        User memory user = User({
            phone: _phone,
            nickName: _nickName,
            addr: msg.sender
        });

        users[_phone] = user;
        userPhones[msg.sender] = _phone;
    }

    /**
    * @notice 修改昵称
    * @param _nickName 昵称
    */
    function changeNickName(bytes32 _nickName) external {
        require(_nickName != bytes32(0), "UserRegistry: params not be null");
        require(_isAddrRegistered(msg.sender), "UserRegistry: current address not register");

        uint256 _phone = userPhones[msg.sender];
        users[_phone].nickName = _nickName;
    }

    /**
     * @notice 重置用户地址
     * @dev 当User.addr对应的私钥丢失时，可通过管理员重置User的addr。
     * @param _phone 手机号
     * @param _newAddr 新外部账户地址
     */
    function restUserAddr(uint256 _phone, address _newAddr) external onlyOwner {
        require(_phone != uint256(0) && _newAddr != address(0), "UserRegistry: params not be null");
        require(_isPhoneExist(_phone), "UserRegistry: current phone not exist");
        require(!_isAddrRegistered(_newAddr), "UserRegistry: current address has already register");

        delete userPhones[users[_phone].addr];
        users[_phone].addr = _newAddr;
        userPhones[_newAddr] = _phone;
    }

    /**
     * @notice 通过地址查询手机号
     * @param _addr 地址
     * @return _phone 手机号
     */
    function searchPhoneByAddr(address _addr) external view returns(uint256 _phone) {
        require(_addr != address(0), "UserRegistry: _addr not be null");
        require(_isAddrRegistered(_addr), "UserRegistry: current address not register");

        _phone = userPhones[_addr];
    }

    /**
     * @notice 手机号是否已存在
     * @param _phone 手机号
     * @return bool 是否存在
     */
    function isPhoneExist(bytes32 _phone) external view returns(bool){
        return _isPhoneExist(_phone);
    }

    function _isPhoneExist(uint256 _phone) internal view returns(bool) {
        return users[_phone].addr != address(0);
    }

    function _isAddrRegistered(address _addr) internal view returns(bool) {
        return userPhones[_addr] != uint256(0);
    }
}