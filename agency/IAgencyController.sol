pragma solidity ^0.4.24;

contract IAgencyController {
    function register(string _agencyName) external;
    function restAgencyAdmin(string _agencyName, uint256 _newAdminUserId) external;
    function verifyAgency(string _agencyName, uint8 _status) external;
    function addMember(string _agencyName, uint256 _memberUserId) external;
    function removeMember(string _agencyName, uint256 _memberUserId) external;
}
