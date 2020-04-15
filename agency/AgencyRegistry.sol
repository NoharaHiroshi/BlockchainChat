pragma solidity ^0.5.8;

import "../Ownable.sol";
import "../user/IUserRegistry.sol";

contract AgencyRegistry is Ownable {

    struct Agency {
        bytes32 agencyName;         // 机构名（唯一性标识）
        uint256 adminUserId;        // 机构管理员ID
        uint256 createdDate;        // 创建时间
    }

    IUserRegistry public userRegistry;

    mapping(bytes32 => Agency) agencies;
    mapping(bytes32 => uint256) agencyIndex;
    bytes32[] agencyNames;

    mapping(bytes32 => uint256[]) agencyMembers;
    mapping(bytes32 => mapping(uint256 => uint256)) agencyMemberIndex;
    mapping(uint256 => bytes32) memberAgency;

    ///////////////
    //// Modifier
    ///////////////

    modifier onlyAgencyAdmin(bytes32 _agencyName) {
        uint256 _userId = userRegistry.searchUserIdByAddr(msg.sender);
        require(_isAgencyAdmin(_agencyName, _userId), "AgencyRegistry: not authorized");
        _;
    }

    ///////////////
    //// Functions
    ///////////////

    constructor(address _userRegistry) public {
        userRegistry = IUserRegistry(_userRegistry);
    }

    /**
     * @notice 注册机构
     * @dev 机构名全局唯一，创建者作为管理员
     * @param _agencyName 机构名
     */
    function register(bytes32 _agencyName) external {
        require(_agencyName != bytes32(0), "AgencyRegistry: params not be null");
        require(!_isAgencyExist(_agencyName), "AgencyRegistry: current agencyName is already exist");
        
        uint256 _adminUserId = userRegistry.searchUserIdByAddr(msg.sender);
        Agency memory agency = Agency({
            agencyName: _agencyName,
            adminUserId: _adminUserId,
            createdDate: now
        });

        agencies[_agencyName] = agency;
        agencyNames.push(_agencyName);
        agencyIndex[_agencyName] = agencyNames.length;
        _addMember(_agencyName, _adminUserId);
    }

    /**
     * @notice 重置机构管理员地址
     * @dev 当Agency.admin对应的私钥丢失时，可用Agency.adminPhone进行验证码校验，验证通过后管理员将重置Agency的admin。
     * @param _agencyName 机构名称
     * @param _adminUserId 新管理员用户ID 
     */
    function restAgencyAdmin(bytes32 _agencyName, uint256 _adminUserId) external onlyOwner {
        require(_agencyName != bytes32(0) && _adminUserId != uint256(0), "AgencyRegistry: params not be null");
        require(userRegistry.isUserExist(_adminUserId), "AgencyRegistry: adminUserId not exist");

        agencies[_agencyName].adminUserId = _adminUserId;
        if(!_isAgencyMember(_agencyName, _adminUserId)) {
            _addMember(_agencyName, _adminUserId);
        }
        
    }

    /**
     * @notice 机构添加成员
     * @dev 限机构管理员调用
     * @param _agencyName 机构名
     * @param _userId 用户名
     */
    function addMember(bytes32 _agencyName, uint256 _userId) external onlyAgencyAdmin(_agencyName){
        _addMember(_agencyName, _userId);
    }

    /**
     * @notice 机构移除成员
     * @dev 限机构管理员调用
     * @param _agencyName 机构名
     * @param _userId 用户名
     */
    function removeMember(bytes32 _agencyName, uint256 _userId) external onlyAgencyAdmin(_agencyName) {
        require(!_isAgencyAdmin(_agencyName, _userId), "AgencyRegistry: adminUser can not remove");
        _removeMember(_agencyName, _userId);
    }

    /**
     * @notice 查询机构信息
     * @param _agencyName 机构名
     * @return _name 机构名
     * @return _adminUserId 机构管理员地址
     * @return _createdDate 机构创建时间
     */
    function searchAgencyInfo(bytes32 _agencyName) external view returns(
        bytes32 _name,
        uint256 _adminUserId,
        uint256 _createdDate
    ) {
        require(_agencyName != bytes32(0), "AgencyRegistry: params not be null");
        require(_isAgencyExist(_agencyName), "AgencyRegistry: current agencyName is already exist");

        Agency memory agency = agencies[_agencyName];
        _name = _agencyName;
        _adminUserId = agency.adminUserId;
        _createdDate = agency.createdDate;
    }

    /**
     * @notice 查询已注册的机构
     * @return bytes32[] 机构名列表
     */
    function searchAgencyNames() external view returns(bytes32[] memory) {
        return agencyNames;
    }

    /**
     * @notice 查询机构成员
     * @return bytes32[] 机构名列表
     */
    function searchAgencyMembers(bytes32 _agencyName) external view returns(uint256[] memory) {
        return agencyMembers[_agencyName];
    }

    /**
     * @notice 查询用户所属机构
     * @param _userId 用户Id
     * @return bytes32 机构名
     */
    function searchMemberAgency(uint256 _userId) external view returns(bytes32) {
        return memberAgency[_userId];
    }

    function _isAgencyAdmin(bytes32 _agencyName, uint256 _userId) internal view returns(bool) {
        require(userRegistry.isUserExist(_userId), "AgencyRegistry: userId not exist");
        return agencies[_agencyName].adminUserId == _userId;
    }

    function _isAgencyExist(bytes32 _agencyName) internal view returns(bool) {
        return agencyIndex[_agencyName] != uint256(0);
    }

    function _isMemberAdded(uint256 _userId) internal view returns(bool) {
        return memberAgency[_userId] != bytes32(0);
    }

    function _isAgencyMember(bytes32 _agencyName, uint256 _userId) internal view returns(bool) {
        return memberAgency[_userId] == _agencyName;
    }
    
    function _addMember(bytes32 _agencyName, uint256 _userId) internal {
        require(_agencyName != bytes32(0) && _userId != uint256(0), "AgencyRegistry: params not be null");
        require(userRegistry.isUserExist(_userId), "AgencyRegistry: userId not exist");
        require(!_isMemberAdded(_userId), "AgencyRegistry: userId has already added");

        agencyMembers[_agencyName].push(_userId);
        agencyMemberIndex[_agencyName][_userId] = agencyMembers[_agencyName].length;
        memberAgency[_userId] = _agencyName;
    }
    
    function _removeMember(bytes32 _agencyName, uint256 _userId) internal {
        require(_agencyName != bytes32(0) && _userId != uint256(0), "AgencyRegistry: params not be null");
        require(_isAgencyMember(_agencyName, _userId), "AgencyRegistry: userId not agency member");

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
    }

}
