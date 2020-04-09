pragma solidity ^0.5.8;

import "../Ownable.sol";

contract UserRegistry is Ownable {
    struct User {
        uint256 userId;             // 用户ID（主键）
        uint256 phone;              // 手机号（唯一）
        bytes32 nickName;           // 昵称
        address addr;               // 外部账户地址
        uint256 createdDate;        // 注册时间
    }

    uint256 id = 1;

    // userId => user
    mapping(uint256 => User) users;
    // addr => userId
    mapping(address => uint256) userAddrIds;
    // phone => userId
    mapping(uint256 => uint256) userPhoneIds;

    ///////////////
    //// Functions
    ///////////////

    /**
     * @notice 注册用户
     * @dev 合约分配的id作为User的userId，msg.sender作为User的addr，phone全局唯一，不同User的nickName可相同
     * @param _phone 手机号
     * @param _nickName 昵称
     */
    function register(uint256 _phone, bytes32 _nickName) external {
        require(_phone != uint256(0) && _nickName != bytes32(0), "UserRegistry: params not be null");
        require(!_isAddrRegistered(msg.sender), "UserRegistry: current address has already register");
        require(!_isPhoneExist(_phone), "UserRegistry: current phone has already exist");

        User memory user = User({
            userId: id,
            phone: _phone,
            nickName: _nickName,
            addr: msg.sender,
            createdDate: now
        });

        users[id] = user;
        userAddrIds[msg.sender] = id;
        userPhoneIds[_phone] = id;
        id++;
    }

    /**
    * @notice 修改昵称
    * @param _nickName 昵称
    */
    function changeNickName(bytes32 _nickName) external {
        require(_nickName != bytes32(0), "UserRegistry: params not be null");
        require(_isAddrRegistered(msg.sender), "UserRegistry: current address not register");

        uint256 _userId = userAddrIds[msg.sender];
        users[_userId].nickName = _nickName;
    }

    /**
     * @notice 重置用户地址
     * @dev 当User.addr对应的私钥丢失时，可用注册时的手机进行验证码校验，验证通过后管理员将重置User的addr。
     * @param _phone 手机号
     * @param _newAddr 新外部账户地址
     */
    function restUserAddr(uint256 _phone, address _newAddr) external onlyOwner {
        require(_phone != uint256(0) && _newAddr != address(0), "UserRegistry: params not be null");
        require(_isPhoneExist(_phone), "UserRegistry: current phone not exist");
        require(!_isAddrRegistered(_newAddr), "UserRegistry: current address has already register");

        uint256 _userId = userPhoneIds[_phone];
        delete userAddrIds[users[_userId].addr];
        users[_userId].addr = _newAddr;
        userAddrIds[_newAddr] = _userId;
    }

    /**
     * @notice 修改用户手机号
     * @dev 需要在链外对_phone，_newPhone分别进行验证码校验
     * @param _phone 原有手机号
     * @param _newPhone 新手机号
     */
    function changeUserPhone(uint256 _phone, uint256 _newPhone) {
        require(_phone != uint256(0) && _newPhone != uint256(0), "UserRegistry: params not be null");
        require(_isPhoneExist(_phone), "UserRegistry: _phone not exist");
        require(!_isPhoneExist(_newPhone), "UserRegistry: _newPhone is already exist");
        require(users[userPhoneIds[_phone]].addr == msg.sender, "UserRegistry: not authorized");

        uint256 _userId = userPhoneIds[_phone];
        delete userPhoneIds[_phone];
        users[_userId].phone = _newPhone;
        userPhoneIds[_newPhone] = _userId;
    }

    /**
     * @notice 通过地址查询手机号
     * @param _addr 地址
     * @return _phone 手机号
     */
    function searchPhoneByAddr(address _addr) external view returns(uint256 _phone) {
        require(_addr != address(0), "UserRegistry: _addr not be null");
        require(_isAddrRegistered(_addr), "UserRegistry: current address not register");

        _phone = users[userAddrIds[_addr]].phone;
    }

    /**
     * @notice 通过手机号查询Id
     * @param _phone 手机号
     * @return _userId 用户Id
     */
    function searchUserIdByPhone(uint256 _phone) external view returns(uint256 _userId) {
        require(_phone != uint256(0), "UserRegistry: _phone not be null");
        require(_isPhoneExist(_phone), "UserRegistry: _phone not exist");

        _userId = userPhoneIds[_phone];
    }

    /**
     * @notice 手机号是否已存在
     * @param _phone 手机号
     * @return bool 是否存在
     */
    function isPhoneExist(uint256 _phone) external view returns(bool){
        return _isPhoneExist(_phone);
    }

    /**
     * @notice userId是否已存在
     * @param _userId 用户Id
     * @return bool 是否存在
     */
    function isUserExist(uint256 _userId) external view returns(bool) {
        return _isUserExist(_userId);
    }

    function _isPhoneExist(uint256 _phone) internal view returns(bool) {
        return userPhoneIds[_phone] != uint256(0);
    }

    function _isUserExist(uint256 _userId) internal view returns(bool) {
        return _userId != uint256(0) && _userId <= id;
    }

    function _isAddrRegistered(address _addr) internal view returns(bool) {
        return userAddrIds[_addr] != uint256(0);
    }
}