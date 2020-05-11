pragma solidity ^0.4.24;

import "../library/Ownable.sol";
import "./AgencyStorageStateful.sol";

/**
 * 机构逻辑合约
 */
contract AgencyController is AgencyStorageStateful, Ownable {

    ///////////////
    //// Event
    ///////////////

    event Register(string indexed agencyName, uint256 indexed adminUserId);
    event RestAgencyAdmin(string indexed agencyName, uint256 indexed newAdminUserId);
    event AddMember(string indexed agencyName, uint256 indexed memberUserId);
    event RemoveMember(string indexed agencyName, uint256 indexed memberUserId);

    ///////////////
    //// Functions
    ///////////////

    /**
     * @notice 注册机构
     * @dev 机构名全局唯一，创建者作为管理员
     * @param _agencyName 机构名
     */
    function register(string _agencyName) external {
        (uint256 _adminUserId, , , , , ) = userStorage.selectByAddr(msg.sender);
        require(agencyStorage.insert(_agencyName, _adminUserId, uint8(1)) == int(1), "AgencyController: register agency error");

        emit Register(_agencyName, _adminUserId);
    }

    /**
     * @notice 重设机构管理员
     * @dev 限机构管理员调用
     * @dev 当Agency.admin对应的私钥丢失时，可用Agency.adminPhone进行验证码校验，验证通过后管理员将重置Agency的admin。
     * @param _agencyName 机构名称
     * @param _newAdminUserId 新管理员用户ID
     */
    function restAgencyAdmin(string _agencyName, uint256 _newAdminUserId) external {
        (uint256 _userId, , , , , ) = userStorage.selectByAddr(msg.sender);
        (, uint256 _adminUserId, uint8 _status, ) = agencyStorage.select(_agencyName);

        require(_userId == _adminUserId, "AgencyController: only agency admin call");
        require(agencyStorage.update(_agencyName, _newAdminUserId, _status) == int(1), "AgencyController: update agency error");

        emit RestAgencyAdmin(_agencyName, _newAdminUserId);
    }

    /**
     * @notice 链管理员审核机构信息
     * @dev 限链管理员调用
     * @dev 当机构认证通过后，才能添加和删减成员
     * @param _agencyName 机构名称
     * @param _status 审核状态
     */
    function verifyAgency(string _agencyName, uint8 _status) external onlyOwner {
        (, uint256 _adminUserId, , ) = agencyStorage.select(_agencyName);
        require(agencyStorage.update(_agencyName, _adminUserId, _status) == int(1), "AgencyController: update agency error");
    }

    /**
     * @notice 机构添加成员
     * @dev 限机构管理员调用
     * @param _agencyName 机构名
     * @param _memberUserId 用户Id
     */
    function addMember(string _agencyName, uint256 _memberUserId) external {
        (uint256 _userId, , , , , ) = userStorage.selectByAddr(msg.sender);
        (, uint256 _adminUserId, uint8 _status, ) = agencyStorage.select(_agencyName);

        require(_userId == _adminUserId, "AgencyController: only agency admin call");
        require(_status == uint8(3), "AgencyController: agency not pass");
        require(agencyUserRelStorage.insert(_agencyName, _memberUserId) == int(1), "AgencyController: agency member add error");

        emit AddMember(_agencyName, _memberUserId);
    }

    /**
    * @notice 机构移除成员
    * @dev 限机构管理员调用
    * @param _agencyName 机构名
    * @param _memberUserId 用户Id
    */
    function removeMember(string _agencyName, uint256 _memberUserId) external {
        (uint256 _userId, , , , , ) = userStorage.selectByAddr(msg.sender);
        (, uint256 _adminUserId, uint8 _status, ) = agencyStorage.select(_agencyName);

        require(_userId == _adminUserId, "AgencyController: only agency admin call");
        require(_status == uint8(3), "AgencyController: agency not pass");
        require(agencyUserRelStorage.remove(_agencyName, _memberUserId) == int(1), "AgencyController: agency member remove error");

        emit RemoveMember(_agencyName, _memberUserId);
    }


}
