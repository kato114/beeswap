// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./interfaces/ISwapRouter.sol";
import "./interfaces/IBeeswapTreasury.sol";

contract BeeswapRouter is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    function initialize (address _weth, address _usdt, address _router, address _treasury) public initializer{
        require(_weth != address(0) && _usdt != address(0) && _router != address(0) && _treasury != address(0), "Beeswap Router: Prams can't be zero address.");
        __Ownable_init();
        weth = _weth;
        usdt = _usdt;
        router = _router;
        treasury = _treasury;
    }

    function chainID() public view returns (uint) {
        return block.chainid;
    }

    function setUsdtAddress(address _usdt) public onlyOwner{
        require(_usdt != address(0), "Beeswap Router: Address is not correct");
        
        usdt = _usdt;
    }

    function setWethAddress(address _weth) public onlyOwner{
        require(_weth != address(0), "Beeswap Router: Address is not correct");
        
        weth = _weth;
    }

    function setRouterAddress(address _router) public onlyOwner{
        require(_router != address(0), "Beeswap Router: Address is not correct");
        
        router = _router;
    }

    function setTreasuryAddress(address _treasury) public onlyOwner{
        require(_treasury != address(0), "Beeswap Router: Address is not correct");
        
        treasury = _treasury;
    }

    function setChainStatus(uint256 cID, bool status) public onlyOwner {
        require(cID > 0, "Beeswap Router: Chain ID can't be zero");
        
        chainStatus[cID] = status;
    }

    function setTokenStatus(address token, bool status) public onlyOwner {
        require(token != address(0), "Beeswap Router: Token address is not correct");
        
        tokenStatus[token] = status;
    }

    function swapInNative(uint toCID, address toToken, address toAddress, uint256 deadline) public payable {
        require(chainStatus[toCID] == true, "Beeswap Router: Not supported chain");
        require(toAddress != address(0), "Beeswap Router: To address is not correct");
        require(msg.value > 0, "Beeswap Router: Amount can't be zero");

        address[] memory pairs;
        pairs[0] = weth;
        pairs[1] = usdt;

        uint256 pBalance = IERC20Upgradeable(usdt).balanceOf(address(this));
        ISwapRouter(router).swapExactETHForTokens{value: msg.value}(0, pairs, address(this), deadline);
        uint256 nBalance = IERC20Upgradeable(usdt).balanceOf(address(this));

        uint256 rBalance = nBalance.sub(pBalance);
        IERC20Upgradeable(usdt).transfer(treasury, rBalance);
        
        emit SwapIn(msg.sender, toAddress, block.chainid, toCID, weth, toToken, rBalance);
    }

    function swapInToken(address fromToken, uint256 amount, uint toCID, address toToken, address toAddress, uint256 deadline) public payable {
        require(chainStatus[toCID] == true, "Beeswap Router: Not supported chain");
        require(tokenStatus[fromToken] == true, "Beeswap Router: Not supported token");
        require(toAddress != address(0), "Beeswap Router: To address is not correct");
        require(amount > 0, "Beeswap Router: Amount can't be zero");

        if(fromToken == usdt) {
            IERC20Upgradeable(usdt).transferFrom(msg.sender, treasury, amount);

            emit SwapIn(msg.sender, toAddress, block.chainid, toCID, fromToken, toToken, amount);
        } else {
            address[] memory pairs;
            pairs[0] = fromToken;
            pairs[1] = usdt;

            IERC20Upgradeable(fromToken).transferFrom(msg.sender, address(this), amount);

            uint256 pBalance = IERC20Upgradeable(usdt).balanceOf(address(this));
            ISwapRouter(router).swapExactTokensForTokens(amount, 0, pairs, address(this), deadline);
            uint256 nBalance = IERC20Upgradeable(usdt).balanceOf(address(this));

            uint256 rBalance = nBalance.sub(pBalance);
            IERC20Upgradeable(usdt).transfer(treasury, rBalance);

            emit SwapIn(msg.sender, toAddress, block.chainid, toCID, fromToken, toToken, rBalance);
        }
    }

    function swapOutNative(uint tID, address toAddress, uint256 amount, uint256 deadline) public onlyOwner {
        require(toAddress != address(0), "Beeswap Router: To address is not correct");
        require(amount > 0, "Beeswap Router: Amount can't be zero");
        
        address[] memory pairs;
        pairs[0] = usdt;
        pairs[1] = weth;

        IBeeswapTreasury(router).approveToRouter(amount);
        IERC20Upgradeable(usdt).transferFrom(treasury, address(this), amount);

        uint256 pBalance = address(this).balance;
        ISwapRouter(router).swapExactTokensForETH(amount, 0, pairs, address(this), deadline);
        uint256 nBalance = address(this).balance;

        uint256 rBalance = nBalance.sub(pBalance);

        payable(toAddress).transfer(rBalance);
        
        emit SwapOut(tID, toAddress, weth, rBalance);
    }

    function swapOutToken(uint tID, address toToken, address toAddress, uint256 amount, uint256 deadline) public onlyOwner {
        require(tokenStatus[toToken] == true, "Beeswap Router: Not supported token");
        require(toAddress != address(0), "Beeswap Router: To address is not correct");
        require(amount > 0, "Beeswap Router: Amount can't be zero");
        
        IBeeswapTreasury(router).approveToRouter(amount);
        if(toToken == usdt) {
            IERC20Upgradeable(usdt).transferFrom(treasury, toAddress, amount);
            
            emit SwapOut(tID, toAddress, toToken, amount);
        } else {
            address[] memory pairs;
            pairs[0] = usdt;
            pairs[1] = toToken;

            IERC20Upgradeable(usdt).transferFrom(treasury, address(this), amount);

            uint256 pBalance = IERC20Upgradeable(toToken).balanceOf(address(this));
            ISwapRouter(router).swapExactTokensForTokens(amount, 0, pairs, address(this), deadline);
            uint256 nBalance = IERC20Upgradeable(toToken).balanceOf(address(this));

            uint256 rBalance = nBalance.sub(pBalance);

            IERC20Upgradeable(toToken).transfer(msg.sender, rBalance);
            
            emit SwapOut(tID, toAddress, toToken, rBalance);
        }

    }
}