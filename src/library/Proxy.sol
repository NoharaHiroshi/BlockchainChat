pragma solidity ^0.4.24;

import "./Ownable.sol";
import "./Address.sol";

/**
 * 入口合约，用于转发交易至逻辑合约
 */
contract Proxy is Ownable {

	// 版本对应的控制合约地址 版本号 => 控制合约地址
	mapping(string => address) internal _versions;

	// 版本列表
	string[] public versionList;

	// 当前版本
	string public version;

	///////////////
	//// Event
	///////////////

	// 事件，更新后触发
	event Upgraded(string indexed newVersion, address indexed newImplementation);

	///////////////
	//// Functions
	///////////////

	// 返回实现地址
	function implementation() public view returns (address) {
		return _versions[version];
	}

	// 更新实现地址
	function upgradeTo(string memory _newVersion, address _newImplementation) public onlyOwner {
		require(implementation() != _newImplementation && _newImplementation != address(0), "Proxy: Old address is not allowed and implementation address should not be 0x");
		require(Address.isContract(_newImplementation), "Proxy: Cannot set a proxy implementation to a non-contract address");
		require(bytes(_newVersion).length > 0, "Proxy: Version should not be empty string");
		version = _newVersion;
		_versions[version] = _newImplementation;
		versionList.push(_newVersion);
		emit Upgraded(_newVersion, _newImplementation);
	}

	// 获取版本对应的逻辑合约地址
	function getImplFromVersion(string  _version) external  view onlyOwner returns(address) {
		require(bytes(_version).length > 0, "Version should not be empty string");
		return _versions[_version];
	}

	// fallback
	function () payable external {
		address _impl = implementation();
		require(_impl != address(0), "implementation not set");

		// 委托调用返回结果
		assembly {
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize)
			let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
			let size := returndatasize
			returndatacopy(ptr, 0, size)

			switch result
			case 0 { revert(ptr, size) }
			default { return(ptr, size) }
		}
	}
}
