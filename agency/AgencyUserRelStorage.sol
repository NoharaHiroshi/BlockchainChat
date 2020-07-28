pragma solidity ^0.4.24;

import "../library/BaseStorage.sol";

/**
 * 机构与用户关联关系合约
 */
contract AgencyUserRelStorage is BaseStorage {

    // 机构名 => 用户Id
    mapping(string => uint256[]) agencyMembers;
    // 机构名 => (用户Id => 用户索引)
    mapping(string => mapping(uint256 => uint256)) agencyMemberIndex;
    // 用户Id => 用户所属机构名
    mapping(uint256 => string) memberAgency;

    /**
    * @notice 插入数据
    * @dev 限入口合约调用
    * @param _agencyName 机构名称
    * @param _userId 消息发送方
    * @return int 提交成功数量
    */
    function insert(
        string memory _agencyName,
        uint256 _userId
    ) public onlyProxy returns(int) {
        require(!isUserExistAgency(_userId), "AgencyUserStorage: current user has already exist");

        agencyMembers[_agencyName].push(_userId);
        agencyMemberIndex[_agencyName][_userId] = agencyMembers[_agencyName].length;
        memberAgency[_userId] = _agencyName;

        emit InsertResult(int(1));

        return int(1);
    }

    /**
    * @notice 查询数据
    * @param _agencyName 机构名称
    * @return _userIds 机构用户Id列表
    */
    function select(string memory _agencyName) public view returns(
        uint256[] memory _userIds
    ){
        _userIds = agencyMembers[_agencyName];
    }

    /**
    * @notice 删除数据
    * @dev 限入口合约调用
    * @param _agencyName 机构名称
    * @param _userId 消息发送方
    * @return int 提交成功数量
    */
    function remove(string memory _agencyName, uint256 _userId) public onlyProxy returns(int){
        require(isUserExistAgency(_userId), "AgencyUserStorage: current user not exist");

        delete memberAgency[_userId];
        uint256 _deleteIndex = agencyMemberIndex[_agencyName][_userId] - 1;
        uint256 _lastIndex = agencyMembers[_agencyName].length - 1;
        uint256 _lastUserId = agencyMembers[_agencyName][_lastIndex];
        if(_deleteIndex != _lastIndex) {
            agencyMembers[_agencyName][_deleteIndex] = _lastUserId;
            agencyMemberIndex[_agencyName][_lastUserId] = _deleteIndex + 1;
        }
        delete agencyMemberIndex[_agencyName][_userId];
        agencyMembers[_agencyName].length--;

        emit RemoveResult(int(1));

        return int(1);
    }

    // 查询用户所属机构
    function selectUserAgency(uint256 _userId) public view returns(string memory _agencyName){
        _agencyName = memberAgency[_userId];
    }

    // 账户是否已属于某个机构
    function isUserExistAgency(uint256 _userId) public view returns(bool) {
        return bytes(memberAgency[_userId]).length != uint(0);
    }
}
