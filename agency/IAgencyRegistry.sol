pragma solidity ^0.5.8;

contract IAgencyRegistry {
    function searchAgencyNames() external view returns(bytes32[] memory);
    function searchAgencyMembers(bytes32 _agencyName) external view returns(uint256[] memory);
    function searchMemberAgency(uint256 _userId) external view returns(bytes32);
}
