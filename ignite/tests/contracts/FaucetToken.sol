pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract FaucetToken is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory _symbol,
        string memory _name,
        uint8 __decimals
    ) ERC20(string(abi.encodePacked(_symbol, _name)), _symbol) {
        _decimals = __decimals;
    }

    function mint(address a,uint256 _amount) external {
        _mint(a, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
