pragma solidity ^0.5.8;

import "../Ownable.sol";

/**
* 用户合约
* 联盟链成员如果想在链上进行操作，需要在用户合约注册成为用户。
* 实现确定外部账户身份；解决私钥丢失带来的影响；用户手机号代替难以记忆的外部账户地址等目的
**/
contract UserRegistry is Ownable {
    struct User {
        uint256 userId;             // 用户ID（主键）
        uint256 phone;              // 手机号（全局唯一）
        string realName;            // 真实姓名
        uint8 sex;                  // 性别 1：女、2：男
        address addr;               // 外部账户地址（全局唯一）
        uint256 createdDate;        // 注册时间
    }
    
    uint8 constant SEX_WOWAM = 1;
    uint8 constant SEX_MAN = 2; 

    // 用于合约分配userId
    uint256 id = 1;

    // 用户userId => User对象
    mapping(uint256 => User) users;
    // 外部账户地址 => 用户userId
    mapping(address => uint256) userAddrIds;
    // 用户手机号 => 用户userId
    mapping(uint256 => uint256) userPhoneIds;

    ///////////////
    //// Event
    ///////////////

    event Register(uint256 indexed userId, uint256 indexed phone, string indexed realName, uint8 sex);
    event RestUserAddr(uint256 indexed userId, uint256 indexed phone, address indexed newAddr);
    event ChangeUserPhone(uint256 indexed userId, uint256 indexed rawPhone, uint256 indexed newPhone);

    ///////////////
    //// Functions
    ///////////////

    /**
     * @notice 注册用户
     * @dev 链外系统负责对用户手机号、真实姓名进行核验，为防止信息在联盟链的泄露，其他个人信息链下保存。
     * @dev 合约分配的id作为User的userId，msg.sender作为User的addr，phone、addr全局唯一，不同User的realName可相同。
     * @param _phone 手机号
     * @param _realName 真实姓名
     * @param _sex 性别
     */
    function register(uint256 _phone, string calldata _realName, uint8 _sex) external {
        require(_phone != uint256(0) && bytes(_realName).length != uint256(0) && _sex != uint8(0), "UserRegistry: params not be null");
        require(!_isAddrRegistered(msg.sender), "UserRegistry: current address has already register");
        require(!_isPhoneExist(_phone), "UserRegistry: current phone has already exist");

        User memory user = User({
            userId: id,
            phone: _phone,
            realName: _realName,
            sex: _sex,
            addr: msg.sender,
            createdDate: now
        });

        users[id] = user;
        userAddrIds[msg.sender] = id;
        userPhoneIds[_phone] = id;
        emit Register(id, _phone, _realName, _sex);
        id++;
    }

    /**
     * @notice 重置用户地址
     * @dev 该方法由链管理员调用
     * @dev 当user.addr对应的私钥丢失时，可输入注册时的手机号_phone，新的地址_newAddr申请替换user.addr。（确保持有_newAddr的私钥）
     * @dev 链外系统将会发送验证码到_phone，验证通过后，链管理员将_phone对应user的_addr替换为_newAddr。
     * @param _phone 注册时的手机号
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
        emit RestUserAddr(_userId, _phone, _newAddr);
    }

    /**
     * @notice 修改用户手机号
     * @dev 链外对_newPhone发送验证码进行验证，确保_newPhone的所有权。
     * @dev 链内调用该方法，会通过msg.sender查询到当前user，并修改当前user的手机号
     * @param _newPhone 新手机号
     */
    function changeUserPhone(uint256 _newPhone) external {
        require(_newPhone != uint256(0), "UserRegistry: params not be null");
        require(!_isPhoneExist(_newPhone), "UserRegistry: _newPhone is already exist");
        require(_isAddrRegistered(msg.sender), "UserRegistry: current address not register");

        uint256 _userId = userAddrIds[msg.sender];
        uint256 _rawPhone = users[_userId].phone;
        delete userPhoneIds[_rawPhone];
        users[_userId].phone = _newPhone;
        userPhoneIds[_newPhone] = _userId;
        emit ChangeUserPhone(_userId, _rawPhone, _newPhone);
    }
    
    /**
     * @notice 查看用户信息 
     * @return _userId 用户Id
     * @return _realName 昵称
     * @return _addr 外部账户地址
     * @return _createdDate 注册时间
     */
    function searchUserInfo() external view returns(
        uint256 _userId,            
        uint256 _phone,          
        string memory _realName,          
        address _addr,              
        uint256 _createdDate      
    ) {
        require(_isAddrRegistered(msg.sender), "UserRegistry: current address not register");

        _userId = userAddrIds[msg.sender];
        User memory user = users[_userId];
        _phone = user.phone;
        _realName = user.realName;
        _addr = user.addr;
        _createdDate = user.createdDate;
    }

    /**
     * @notice 通过外部地址查询手机号
     * @param _addr 外部地址
     * @return _phone 手机号
     */
    function searchPhoneByAddr(address _addr) external view returns(uint256 _phone) {
        require(_addr != address(0), "UserRegistry: _addr not be null");
        require(_isAddrRegistered(_addr), "UserRegistry: current address not register");

        _phone = users[userAddrIds[_addr]].phone;
    }
    
    /**
     * @notice 通过外部地址查询userId
     * @param _addr 外部地址
     * @return _userId 用户Id
     */
    function searchUserIdByAddr(address _addr) external view returns(uint256 _userId) {
        require(_addr != address(0), "UserRegistry: _addr not be null");
        require(_isAddrRegistered(_addr), "UserRegistry: current address not register");

        _userId = userAddrIds[_addr];
    }

    /**
     * @notice 通过手机号查询userId
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
        return _userId != uint256(0) && _userId < id;
    }

    function _isAddrRegistered(address _addr) internal view returns(bool) {
        return userAddrIds[_addr] != uint256(0);
    }
}