// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract BeeswapTreasury is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

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
        require(router == _msgSender(), "Beeswap Treasury: caller is not router contract");
        _;
    }

    receive() external payable {
    }

    function initialize (address _usdt) public initializer{
        require(_usdt != address(0), "Beeswap Treasury: Prams can't be zero address.");
        __Ownable_init();
        usdt = _usdt;
    }

    function setUsdtAddress(address _usdt) public onlyOwner{
        require(_usdt != address(0), "Beeswap Router: Address is not correct");
        
        usdt = _usdt;
    }

    function setRouterAddress(address _router) public onlyOwner{
        require(_router != address(0), "Beeswap Router: Address is not correct");
        
        router = _router;
    }

    function approveToRouter(uint256 amount) public onlyRouter {
        require(amount > 0, "Beeswap Router: Deposit amount must be greater than zero");
        IERC20Upgradeable(usdt).approve(router, amount);
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "Beeswap Router: Deposit amount must be greater than zero");

        IERC20Upgradeable(usdt).transferFrom(msg.sender, address(this), amount);

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
        require(amount > 0, "Beeswap Router: Withdraw amount must be greater than zero");

        UserInfo storage user = userInfoList[msg.sender];

        require(user.status == true && user.depositAmount >= amount, "Beeswap Router: Withdrawal amount is zero");
        user.depositAmount = user.depositAmount.sub(amount);

        IERC20Upgradeable(usdt).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }
    
    function claim() public {
        UserInfo storage user = userInfoList[msg.sender];

        require(user.status == true && user.pendingReward > 0, "Beeswap Router: Claimable amount is zero");

        IERC20Upgradeable(usdt).transfer(msg.sender, user.pendingReward);
        user.pendingReward = 0;
        user.claimedReward = user.claimedReward.add(user.pendingReward);

        emit Withdraw(msg.sender, user.pendingReward);
    }
}