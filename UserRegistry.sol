pragma solidity ^0.5.8;

contract UserRegistry {

    struct User {
        bytes32 userName;
        bytes32 nickName;
        address owner;
        uint256 lockedTimestamp;
        uint256 lockedTimes;
    }

    mapping(bytes32 => User) users;
    mapping(address => bytes32) userNames;

    uint256 constant LOCK_TIME = 3 days;

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

    function changeNickName(bytes32 _nickName) external {
        require(_nickName != bytes32(0), "UserRegistry: params not be null");
        require(_isAddrRegistered(msg.sender), "UserRegistry: current address not register");
        
        bytes32 _userName = userNames[msg.sender];
        users[_userName].nickName = _nickName;
    }

    function lockUser(bytes32 _userName) external {
        require(_isUserNameExist(_userName), "UserRegistry: current userName not exist");
        require(!_isLocked(_userName), "UserRegistry: current userName has already locked");
        
        users[_userName].lockedTimestamp = now;
        users[_userName].lockedTimes++;
    }

    function unlockUser() external {
        require(_isAddrRegistered(msg.sender), "UserRegistry: current address not register");
        
        bytes32 _userName = userNames[msg.sender];
        users[_userName].lockedTimestamp = uint256(0);
    }

    function changeUserOwner(bytes32 _userName) external {
        require(!_isAddrRegistered(msg.sender), "UserRegistry: current address has already register");
        require(_isUserNameExist(_userName), "UserRegistry: current userName not exist");
        require(_isLocked(_userName), "UserRegistry: current userName not locked");
        require(now > users[_userName].lockedTimestamp + users[_userName].lockedTimes * LOCK_TIME, "UserRegistry: current userName is locking");
        
        delete userNames[users[_userName].owner];
        users[_userName].owner = msg.sender;
        users[_userName].lockedTimestamp = uint256(0);
        userNames[msg.sender] = _userName;
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
