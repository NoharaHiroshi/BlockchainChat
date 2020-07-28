pragma solidity ^0.4.24;

import "../library/BaseStorage.sol";

/**
 * 机构存储合约
 */
contract AgencyStorage is BaseStorage {

    /**
    *  机构
    *  +---------------+---------------------+---------------------------------------------------+
    *  | Field         | Type                | Desc                                              |
    *  +---------------+---------------------+---------------------------------------------------+
    *  | agency_name   | string              | 机构名                                            |
    *  | admin_user_id | uint256             | 机构管理员Id                                      |
    *  | status        | uint8               | 状态 1：待审核、2：审核未通过、3：审核通过        |
    *  | created_date  | uint256             | 创建时间                                          |
    *  +---------------+---------------------+---------------------------------------------------+
    */
    struct Agency {
        string agencyName;
        uint256 adminUserId;
        uint8 status;
        uint256 createdDate;
    }

    mapping(string => Agency) agencies;

    ///////////////
    //// Functions
    ///////////////

    /**
    * @notice 插入数据
    * @dev 限入口合约调用
    * @param _agencyName 机构名称
    * @param _adminUserId 管理员用户编号
    * @param _status 机构状态
    * @return int 提交成功数量
    */
    function insert(
        string _agencyName,
        uint256 _adminUserId,
        uint8 _status
    ) public onlyProxy returns(int) {
        require(!_isAgencyNameExist(_agencyName), "AgencyRegistry: current agencyName is already exist");

        Agency memory agency = Agency({
            agencyName: _agencyName,
            adminUserId: _adminUserId,
            status: _status,
            createdDate: now
        });

        agencies[_agencyName] = agency;
        return int(1);
    }

    /**
    * @notice 查询数据
    * @param _agencyName 机构名称
    * @return _adminUserId 管理员用户编号
    * @return _status 机构状态
    * @return _createdDate 创建时间
    */
    function select(string _agencyName) public view returns(
        string memory _name,
        uint256 _adminUserId,
        uint8 _status,
        uint256 _createdDate
    ){
        require(_isAgencyNameExist(_agencyName), "AgencyRegistry: current agencyName not exist");

        Agency memory agency = agencies[_agencyName];

        _name = agency.agencyName;
        _adminUserId = agency.adminUserId;
        _status = agency.status;
        _createdDate = agency.createdDate;
    }

    /**
    * @notice 更新数据
    * @dev 限入口合约调用
    * @param _agencyName 机构名称
    * @param _adminUserId 管理员用户编号
    * @param _status 机构状态
    * @return int 提交成功数量
    */
    function update(
        string memory _agencyName,
        uint256 _adminUserId,
        uint8 _status
    ) public onlyProxy returns(int) {
        require(_isAgencyNameExist(_agencyName), "AgencyStorage: current name not exist");

        agencies[_agencyName].adminUserId = _adminUserId;
        agencies[_agencyName].status = _status;

        emit UpdateResult(int(1));

        return int(1);
    }

    /**
    * @notice 删除数据
    * @dev 限入口合约调用
    * @param _agencyName 机构名称
    * @return int 提交成功数量
    */
    function remove(string memory _agencyName) public onlyProxy returns(int){
        require(_isAgencyNameExist(_agencyName), "AgencyStorage: current name not exist");

        delete agencies[_agencyName];

        emit RemoveResult(int(1));

        return int(1);
    }

    // 机构名是否存在
    function isAgencyNameExist(string memory _agencyName) public view returns(bool) {
        return _isAgencyNameExist(_agencyName);
    }

    function _isAgencyNameExist(string memory _agencyName) internal view returns(bool) {
        return agencies[_agencyName].adminUserId != uint256(0);
    }


}
