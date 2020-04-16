pragma solidity ^0.5.8;

contract ApprovalRegistry {

    struct Approval {
        uint256 id;
        string name;
        bytes32 contentHash;
        uint256 initiatorId;
        uint8 status;
    }

    struct ApprovalProcess {
        uint256 checkerId;
        uint256 state;
    }

    uint256 approvalId = 1;

    // approvalId => Approval
    mapping(uint256 => Approval) approvals;
    // approvalId => ApprovalProcess[]
    mapping(uint256 => ApprovalProcess[]) approvalProcesses;
    // approvalId => userId
    mapping(uint256 => uint256[]) approvalUsers;
    // userId => approvalId
    mapping(uint256 => uint256[]) userApprovals;




}
