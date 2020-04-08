pragma solidity ^0.5.8;

contract UserRegistry {

    struct User {
        bytes32 userName;
        bytes32 nickName;
        address owner;
        uint256 lockedTimestamp;
        uint256 lockedTimes;
        address lockedAddr;
    }

    mapping(bytes32 => User) users;
    mapping(address => bytes32) userNames;

    uint256 constant LOCK_TIME = 3 days;

    /**
     * @notice 注册用户
     * @dev 当前address作为用户owner，用户以userName作为唯一性标识，nickName可相同
     * @param _userName 用户名
     * @param _nickName 昵称
     */
    function register(bytes32 _userName, bytes32 _nickName) external {
        require(_userName != bytes32(0) && _nickName != bytes32(0), "UserRegistry: params not be null");
        require(!_isAddrRegistered(msg.sender), "UserRegistry: current address has already register");
        require(!_isUserNameExist(_userName), "UserRegistry: current userName has already exist");
        
        User memory user = User({
            userName: _userName,
            nickName: _nickName,
            owner: msg.sender,
            lockedTimestamp: uint256(0),
            lockedTimes: uint256(0)
        });
        users[_userName] = user;
        userNames[msg.sender] = _userName;
    }

    /**
     * @notice 修改昵称
     * @param _nickName 昵称
     */
    function changeNickName(bytes32 _nickName) external {
        require(_nickName != bytes32(0), "UserRegistry: params not be null");
        require(_isAddrRegistered(msg.sender), "UserRegistry: current address not register");
        
        bytes32 _userName = userNames[msg.sender];
        users[_userName].nickName = _nickName;
    }

    /**
     * @notice 锁定用户
     * @dev 当用户丢失私钥后，可根据用户名锁定注册用户，锁定期过后可用其他地址替换用户owner
     * @dev 如果非用户owner恶意锁定用户，该用户owner可在锁定期内调用unlockUser进行解锁，随着锁定次数增加，会增加锁定时间。
     * @param _userName 用户名
     */
    function lockUser(bytes32 _userName) external {
        require(_isUserNameExist(_userName), "UserRegistry: current userName not exist");
        require(!_isLocked(_userName), "UserRegistry: current userName has already locked");
        
        users[_userName].lockedTimestamp = now;
        users[_userName].lockedAddr = msg.sender;
        users[_userName].lockedTimes++;
    }

    /**
     * @notice 解锁用户
     * @dev 用户owner调用，解除当前用户锁定状态
     */
    function unlockUser() external {
        require(_isAddrRegistered(msg.sender), "UserRegistry: current address not register");
        
        bytes32 _userName = userNames[msg.sender];
        users[_userName].lockedTimestamp = uint256(0);
    }

    /**
     * @notice 修改用户owner
     * @dev 锁定期过后，可调用该方法替换用户owner为当前调用者，并且当前调用者地址必须为锁定用户时的地址，防止冒名替换
     * @param _userName 用户名
     */
    function changeUserOwner(bytes32 _userName) external {
        require(!_isAddrRegistered(msg.sender), "UserRegistry: current address has already register");
        require(_isUserNameExist(_userName), "UserRegistry: current userName not exist");
        require(_isLocked(_userName), "UserRegistry: current userName not locked");
        require(now > users[_userName].lockedTimestamp + users[_userName].lockedTimes * LOCK_TIME, "UserRegistry: current userName is locking");
        require(msg.sender == users[_userName].lockedAddr, "UserRegistry: current address not same as lock address");
        
        delete userNames[users[_userName].owner];
        users[_userName].owner = msg.sender;
        users[_userName].lockedTimestamp = uint256(0);
        userNames[msg.sender] = _userName;
    }

    function searchUserName() external view returns(bytes32 _userName) {
        require(_isAddrRegistered(msg.sender), "UserRegistry: current address not register");
        _userName = userNames[msg.sender];
    }

    function searchUserInfo() external view returns(
        bytes32 _userName;
        bytes32 _nickName;
        address _owner;
        uint256 _lockedTimestamp;
        uint256 _lockedTimes;
    ) {
        require(_isAddrRegistered(msg.sender), "UserRegistry: current address not register");
        _userName = userNames[msg.sender];
        User memory userInfo = users[_userName];
        _nickName = userInfo.nickName;
        _owner = userInfo.owner;
        _lockedTimestamp = userInfo.lockedTimestamp;
        _lockedTimes = userInfo.lockedTimes;
    }

    function searchUserLockTime(bytes32 _userName) returns(uint256 _closingDate) {
        require(_isUserNameExist(_userName), "UserRegistry: current userName not exist");
        require(_isLocked(_userName), "UserRegistry: current userName not locked");
        _closingDate = users[_userName].lockedTimestamp + users[_userName].lockedTimes * LOCK_TIME;
    }

    function searchUserNameByAddr(address _addr) external view returns(bytes32 _userName) {
        require(_addr != address(0), "UserRegistry: _addr not be null");
        require(_isAddrRegistered(_addr), "UserRegistry: current address not register");
        
        _userName = userNames[_addr];
    }
    
    function isUserNameExist(bytes32 _userName) external view returns(bool){
        return _isUserNameExist(_userName);
    }
    
    function _isLocked(bytes32 _userName) internal view returns(bool) {
        return users[_userName].lockedTimestamp != uint256(0);
    }
    
    function _isUserNameExist(bytes32 _userName) internal view returns(bool) {
        return users[_userName].userName != bytes32(0);
    }
    
    function _isAddrRegistered(address _addr) internal view returns(bool) {
        return userNames[_addr] != bytes32(0);
    }
    
}
