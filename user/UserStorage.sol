pragma solidity ^0.4.24;

import "../library/BaseStorage.sol";

contract UserStorage is BaseStorage {

    /**
    * 用户
    * +--------------+---------------------+-------------------------+
    * | Field        | Type                | Desc                    |
    * +--------------+---------------------+-------------------------+
    * | user_id      | uint256             | 用户ID，主键            |
    * | phone        | uint256             | 手机号，全局唯一        |
    * | name         | string              | 用户名                  |
    * | sex          | string              | 性别                    |
    * | addr         | address             | 外部账户地址，全局唯一  |
    * | created_date | uint256             | 注册时间                |
    * +--------------+---------------------+-------------------------+
    */
    struct User {
        uint256 userId;
        uint256 phone;
        string name;
        string sex;
        address addr;
        uint256 createdDate;
    }

    // 用户userId => User对象
    mapping(uint256 => User) users;
    // 外部账户地址 => 用户userId
    mapping(address => uint256) userAddrIds;
    // 用户手机号 => 用户userId
    mapping(uint256 => uint256) userPhoneIds;

    /**
    * @notice 插入数据
    * @dev 限代理合约调用
    * @dev user_id为主键, phone, addr为唯一性索引
    * @param _userId 用户Id
    * @param _phone 用户手机号
    * @param _name 用户名
    * @param _sex 用户性别
    * @param _addr 用户外部账户地址
    * @return int 提交成功数量
    */
    function insert(
        uint256 _userId,
        uint256 _phone,
        string memory _name,
        string memory _sex,
        address _addr
    ) public onlyProxy returns(int) {
        require(!_isUserIdExist(_userId), "UserStorage: current id has already exist");
        require(!_isPhoneExist(_phone), "UserStorage: current phone has already exist");
        require(!_isAddrExist(_addr), "UserStorage: current addr has already exist");

        User memory user = User({
            userId: _userId,
            phone: _phone,
            name: _name,
            sex: _sex,
            addr: _addr,
            createdDate: now
        });

        users[_userId] = user;
        userAddrIds[_addr] = _userId;
        userPhoneIds[_phone] = _userId;

        emit InsertResult(int(1));
        
        return int(1);
    }

    /**
    * @notice 通过userId查询数据
    * @param _userId 用户Id
    * @return _id 用户Id
    * @return _phone 用户手机号
    * @return _name 用户名
    * @return _sex 用户性别
    * @return _addr 用户外部账户地址
    * @return _createdDate 创建时间
    */
    function select(uint256 _userId) public view returns(
        uint256 _id,
        uint256 _phone,
        string memory _name,
        string memory _sex,
        address _addr,
        uint256 _createdDate
    ){
        require(_isUserIdExist(_userId), "UserStorage: current id not exist");

        User memory user = users[_userId];
        _id = _userId;
        _phone = user.phone;
        _name = user.name;
        _sex = user.sex;
        _addr = user.addr;
        _createdDate = user.createdDate;
    }

    /**
    * @notice 通过手机号查询数据
    * @param _phoneNum 用户手机号
    * @return _id 用户Id
    * @return _phone 用户手机号
    * @return _name 用户名
    * @return _sex 用户性别
    * @return _addr 用户外部账户地址
    * @return _createdDate 创建时间
    */
    function selectByPhone(uint256 _phoneNum) public view returns(
        uint256 _id,
        uint256 _phone,
        string memory _name,
        string memory _sex,
        address _addr,
        uint256 _createdDate
    ){
        uint256 userId = userPhoneIds[_phoneNum];
        (_id, _phone, _name, _sex, _addr, _createdDate) = select(userId);
    }

    /**
     * @notice 通过外部账号查看用户信息
     * @param _address 外部账户地址
     * @return _userId 用户Id
     * @return _phone 用户手机号
     * @return _name 用户名
     * @return _sex 用户性别
     * @return _addr 用户外部账户地址
     * @return _createdDate 注册时间
     */
    function selectByAddr(address _address) public view returns(
        uint256 _id,
        uint256 _phone,
        string memory _name,
        string memory _sex,
        address _addr,
        uint256 _createdDate
    ){
        uint256 userId = userAddrIds[_address];
        (_id, _phone, _name, _sex, _addr, _createdDate) = select(userId);
    }

    /**
    * @notice 更新数据
    * @dev 限代理合约调用
    * @param _userId 用户Id
    * @param _phone 用户手机号
    * @param _name 用户名
    * @param _sex 用户性别
    * @param _addr 用户外部账户地址
    * @return int 提交成功数量
    */
    function update(
        uint256 _userId,
        uint256 _phone,
        string memory _name,
        string memory _sex,
        address _addr
    ) public onlyProxy returns(int) {
        require(_isUserIdExist(_userId), "UserStorage: current id not exist");

        User memory user = users[_userId];

        if(user.phone != _phone){
            require(!_isPhoneExist(_phone), "UserStorage: current phone has already exist");
            users[_userId].phone = _phone;
            delete userPhoneIds[user.phone];
            userPhoneIds[_phone] = _userId;
        }
        if(user.addr != _addr) {
            require(!_isAddrExist(_addr), "UserStorage: current addr has already exist");
            users[_userId].addr = _addr;
            delete userAddrIds[user.addr];
            userAddrIds[_addr] = _userId;
        }
        user.name = _name;
        user.sex = _sex;

        emit UpdateResult(int(1));

        return int(1);
    }

    /**
    * @notice 删除数据
    * @dev 限代理合约调用
    * @param _userId 用户Id
    * @return int 提交成功数量
    */
    function remove(uint256 _userId) public onlyProxy returns(int){
        ( ,uint256 _rawPhone, , , address _rawAddr, ) = select(_userId);

        delete users[_userId];
        delete userPhoneIds[_rawPhone];
        delete userAddrIds[_rawAddr];

        emit RemoveResult(int(1));

        return int(1);
    }

    // 用户Id是否存在
    function isUserIdExist(uint256 _id) external view returns(bool) {
        return _isUserIdExist(_id);
    }

    // 手机号是否存在
    function isPhoneExist(uint256 _phone) external view returns(bool) {
        return _isPhoneExist(_phone);
    }

    // 外部账户地址是否存在
    function isAddrExist(address _addr) external view returns(bool) {
        return _isAddrExist(_addr);
    }

    function _isUserIdExist(uint256 _id) internal view returns(bool) {
        return users[_id].userId != uint256(0);
    }

    function _isPhoneExist(uint256 _phone) internal view returns(bool) {
        return userPhoneIds[_phone] != uint256(0);
    }

    function _isAddrExist(address _addr) internal view returns(bool) {
        return userAddrIds[_addr] != uint256(0);
    }
}
