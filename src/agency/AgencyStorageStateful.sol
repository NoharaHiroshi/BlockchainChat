pragma solidity ^0.4.24;

import "./AgencyStorage.sol";
import "./AgencyUserRelStorage.sol";
import "../user/UserStorage.sol";

/**
 * 机构引入的存储合约
 */
contract AgencyStorageStateful {
    AgencyStorage public agencyStorage;
    AgencyUserRelStorage public agencyUserRelStorage;
    UserStorage public userStorage;
}
