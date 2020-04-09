pragma solidity ^0.5.8;

import "../Ownable.sol";
import "../user/IUserRegistry.sol";

contract AgencyRegistry is Ownable {

    struct Agency {
        bytes32 agencyName;         // 机构名（唯一性标识）
        address admin;              // 机构管理员
        uint256 adminPhone;         // 机构管理员手机号
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

    modifier onlySelf(bytes32 _agencyName) {
        require(_isAgencyAdmin(_agencyName), "AgencyRegistry: not authorized");
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
     * @param _adminPhone 管理员手机号
     */
    function register(bytes32 _agencyName, uint256 _adminPhone) external {
        require(_agencyName != bytes32(0), "AgencyRegistry: params not be null");
        require(_isAgencyExist(_agencyName), "AgencyRegistry: current agencyName is already exist");

        Agency memory agency = Agency({
            agencyName: _agencyName,
            admin: msg.sender,
            adminPhone: _adminPhone,
            createdDate: now
        });

        agencies[_agencyName] = agency;
        agencyNames.push(_agencyName);
        agencyIndex[_agencyName] = agencyNames.length;
    }

    /**
     * @notice 重置机构管理员地址
     * @dev 当Agency.admin对应的私钥丢失时，可用Agency.adminPhone进行验证码校验，验证通过后管理员将重置Agency的admin。
     * @param _agencyName 机构名称
     * @param _newAddr 新外部账户地址
     */
    function restAgencyAdmin(bytes32 _agencyName, address _newAddr) external view onlyOwner {
        require(_agencyName != bytes32(0) && _newAddr != address(0), "AgencyRegistry: params not be null");

        Agency memory agency = agencies[_agencyName];
        agency.admin = _newAddr;
    }

    /**
     * @notice 机构添加成员
     * @dev 限机构管理员调用
     * @param _agencyName 机构名
     * @param _userId 用户名
     */
    function addMember(bytes32 _agencyName, uint256 _userId) external onlySelf(_agencyName){
        require(_agencyName != bytes32(0) && _userId != uint256(0), "AgencyRegistry: params not be null");
        require(userRegistry.isUserExist(_userId), "AgencyRegistry: userId not exist");
        require(!_isMemberAdded(_userId), "AgencyRegistry: userId has already added");

        agencyMembers[_agencyName].push(_userId);
        agencyMemberIndex[_agencyName][_userId] = agencyMembers[_agencyName].length;
        memberAgency[_userId] = _agencyName;
    }

    /**
     * @notice 机构移除成员
     * @dev 限机构管理员调用
     * @param _agencyName 机构名
     * @param _userId 用户名
     */
    function removeMember(bytes32 _agencyName, uint256 _userId) external onlySelf(_agencyName) {
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

    /**
     * @notice 查询机构信息
     * @param _agencyName 机构名
     * @return _name 机构名
     * @return _admin 机构管理员地址
     * @return _adminPhone 机构管理员手机号
     * @return _createdDate 机构创建时间
     */
    function searchAgencyInfo(bytes32 _agencyName) external view returns(
        bytes32 _name,
        address _admin,
        uint256 _adminPhone,
        uint256 _createdDate
    ) {
        require(_agencyName != bytes32(0), "AgencyRegistry: params not be null");
        require(_isAgencyExist(_agencyName), "AgencyRegistry: current agencyName is already exist");

        Agency memory agency = agencies[_agencyName];
        _name = _agencyName;
        _admin = agency.admin;
        _adminPhone = agency.adminPhone;
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

    function _isAgencyAdmin(bytes32 _agencyName) internal view returns(bool) {
        return agencies[_agencyName].admin == msg.sender;
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

}
