pragma solidity ^0.4.24;

import "../library/Proxy.sol";
import "./AgencyStorageStateful.sol";

/**
 * 机构代理合约
 */
contract AgencyProxy is AgencyStorageStateful, Proxy {

    ///////////////
    //// Event
    ///////////////

    event SetStorage(address indexed operator, address indexed agencyStorage, address agencyUserRelStorage, address userStorage);

    ///////////////
    //// Functions
    ///////////////

    /**
    * @notice 设置存储
    * @dev 限链管理员调用
    * @param _agencyStorage 机构存储合约
    * @param _agencyUserRelStorage 机构用户关联关系存储合约
    * @param _userStorage 用户存储合约
    */
    function setStorage(address _agencyStorage, address _agencyUserRelStorage, address _userStorage) external onlyOwner {
        agencyStorage = AgencyStorage(_agencyStorage);
        agencyUserRelStorage = AgencyUserRelStorage(_agencyUserRelStorage);
        userStorage = UserStorage(_userStorage);
        emit SetStorage(msg.sender, _agencyStorage, _agencyUserRelStorage, _userStorage);
    }
}
