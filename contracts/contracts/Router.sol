// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/ITreasury.sol";

contract Router is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public weth; 
    address public usdt; 
    address public router; 
    address public treasury; 

    mapping(uint256 => bool) chainStatus;
    mapping(address => bool) tokenStatus;
    
    event SwapIn(address indexed from, address to, uint256 fromChain, uint256 toChain, address indexed fromToken, address indexed toToken, uint256 amount);
    event SwapOut(uint256 txId, address indexed to, address indexed toToken, uint256 amount);

    receive() external payable {
    }
    
    constructor(address _weth, address _usdt, address _router, address _treasury) {
        require(_weth != address(0) && _usdt != address(0) && _router != address(0) && _treasury != address(0), "Router: Prams can't be zero address.");
        weth = _weth;
        usdt = _usdt;
        router = _router;
        treasury = _treasury;
    }

    function chainID() public view returns (uint) {
        return block.chainid;
    }

    function setUsdtAddress(address _usdt) public onlyOwner{
        require(_usdt != address(0), "Router: Address is not correct");
        
        usdt = _usdt;
    }

    function setWethAddress(address _weth) public onlyOwner{
        require(_weth != address(0), "Router: Address is not correct");
        
        weth = _weth;
    }

    function setRouterAddress(address _router) public onlyOwner{
        require(_router != address(0), "Router: Address is not correct");
        
        router = _router;
    }

    function setTreasuryAddress(address _treasury) public onlyOwner{
        require(_treasury != address(0), "Router: Address is not correct");
        
        treasury = _treasury;
    }

    function setChainStatus(uint256 cID, bool status) public onlyOwner {
        require(cID > 0, "Router: Chain ID can't be zero");
        
        chainStatus[cID] = status;
    }

    function setTokenStatus(address token, bool status) public onlyOwner {
        require(token != address(0), "Router: Token address is not correct");
        
        tokenStatus[token] = status;
    }

    function swapInNative(uint toCID, address[] calldata pairs, address toToken, address toAddress, uint256 deadline) public payable {
        require(chainStatus[toCID] == true, "Router: Not supported chain");
        require(toAddress != address(0), "Router: To address is not correct");
        require(msg.value > 0, "Router: Amount can't be zero");

        uint256 pBalance = IERC20(usdt).balanceOf(address(this));
        IRouter(router).swapExactETHForTokens{value: msg.value}(0, pairs, address(this), deadline);
        uint256 nBalance = IERC20(usdt).balanceOf(address(this));

        uint256 rBalance = nBalance.sub(pBalance);
        IERC20(usdt).transfer(treasury, rBalance);
        
        emit SwapIn(msg.sender, toAddress, block.chainid, toCID, weth, toToken, rBalance);
    }

    function swapInToken(address fromToken, address[] calldata pairs, uint256 amount, uint toCID, address toToken, address toAddress, uint256 deadline) public {
        require(chainStatus[toCID] == true, "Router: Not supported chain");
        require(tokenStatus[fromToken] == true, "Router: Not supported token");
        require(toAddress != address(0), "Router: To address is not correct");
        require(amount > 0, "Router: Amount can't be zero");

        if(fromToken == usdt) {
            IERC20(usdt).transferFrom(msg.sender, treasury, amount);

            emit SwapIn(msg.sender, toAddress, block.chainid, toCID, fromToken, toToken, amount);
        } else {
            IERC20(fromToken).transferFrom(msg.sender, address(this), amount);
            IERC20(fromToken).approve(router, amount);

            uint256 pBalance = IERC20(usdt).balanceOf(address(this));
            IRouter(router).swapExactTokensForTokens(amount, 0, pairs, treasury, deadline);
            uint256 nBalance = IERC20(usdt).balanceOf(address(this));

            uint256 rBalance = nBalance.sub(pBalance);
            IERC20(usdt).transfer(treasury, rBalance);

            emit SwapIn(msg.sender, toAddress, block.chainid, toCID, fromToken, toToken, rBalance);
        }
    }

    function swapOutNative(uint tID, address[] calldata pairs, address toAddress, uint256 amount, uint256 deadline) public onlyOwner {
        require(toAddress != address(0), "Router: To address is not correct");
        require(amount > 0, "Router: Amount can't be zero");

        ITreasury(treasury).approveToRouter(amount);
        IERC20(usdt).transferFrom(treasury, address(this), amount);

        uint256 pBalance = address(this).balance;
        IERC20(usdt).approve(router, amount);
        IRouter(router).swapExactTokensForETH(amount, 0, pairs, address(this), deadline);
        uint256 nBalance = address(this).balance;

        uint256 rBalance = nBalance.sub(pBalance);

        payable(toAddress).transfer(rBalance);
        
        emit SwapOut(tID, toAddress, weth, rBalance);
    }

    function swapOutToken(uint tID, address[] calldata pairs, address toToken, address toAddress, uint256 amount, uint256 deadline) public onlyOwner {
        require(tokenStatus[toToken] == true, "Router: Not supported token");
        require(toAddress != address(0), "Router: To address is not correct");
        require(amount > 0, "Router: Amount can't be zero");
        
        ITreasury(treasury).approveToRouter(amount);
        if(toToken == usdt) {
            IERC20(usdt).transferFrom(treasury, toAddress, amount);
            
            emit SwapOut(tID, toAddress, toToken, amount);
        } else {
            IERC20(usdt).transferFrom(treasury, address(this), amount);

            uint256 pBalance = IERC20(toToken).balanceOf(address(this));
            IERC20(usdt).approve(router, amount);
            IRouter(router).swapExactTokensForTokens(amount, 0, pairs, address(this), deadline);
            uint256 nBalance = IERC20(toToken).balanceOf(address(this));

            uint256 rBalance = nBalance.sub(pBalance);

            IERC20(toToken).transfer(msg.sender, rBalance);
            
            emit SwapOut(tID, toAddress, toToken, rBalance);
        }

    }
}