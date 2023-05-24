// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Treasury is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 depositAmount;
        uint256 pendingReward;
        uint256 claimedReward;
        bool status;
    }

    address public usdt;
    address public router;

    address[] public userList;
    mapping(address => UserInfo) public userInfoList;
    
    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event Claim(address indexed to, uint256 amount);

    modifier onlyRouter() {
        require(router == _msgSender(), "Treasury: caller is not router contract");
        _;
    }

    receive() external payable {
    }
    
    constructor(address _usdt) {
        usdt = _usdt;
    }

    function setUsdtAddress(address _usdt) public onlyOwner{
        require(_usdt != address(0), "Router: Address is not correct");
        
        usdt = _usdt;
    }

    function setRouterAddress(address _router) public onlyOwner{
        require(_router != address(0), "Router: Address is not correct");
        
        router = _router;
    }

    function approveToRouter(uint256 amount) public onlyRouter {
        require(amount > 0, "Router: Deposit amount must be greater than zero");
        IERC20(usdt).approve(router, amount);
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "Router: Deposit amount must be greater than zero");

        IERC20(usdt).transferFrom(msg.sender, address(this), amount);

        UserInfo storage user = userInfoList[msg.sender];

        if(user.status == false) {
            userList.push(msg.sender);
            
            user.depositAmount = amount;
            user.status = true;
        } else {
            user.depositAmount = user.depositAmount.add(amount);
        }


        emit Deposit(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) public {
        require(amount > 0, "Router: Withdraw amount must be greater than zero");

        UserInfo storage user = userInfoList[msg.sender];

        require(user.status == true && user.depositAmount >= amount, "Router: Withdrawal amount is zero");
        user.depositAmount = user.depositAmount.sub(amount);

        IERC20(usdt).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }
    
    function claim() public {
        UserInfo storage user = userInfoList[msg.sender];

        require(user.status == true && user.pendingReward > 0, "Router: Claimable amount is zero");

        IERC20(usdt).transfer(msg.sender, user.pendingReward);
        user.pendingReward = 0;
        user.claimedReward = user.claimedReward.add(user.pendingReward);

        emit Withdraw(msg.sender, user.pendingReward);
    }
}