// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Token is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

interface IFactory {
    function getExchange(address _tokenAddress) external returns (address);
}

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens) external payable;
    function ethToTokenTransfer(
        uint256 _minTokens,
        address _recipient
    ) external payable;
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Exchange is ERC20 {
    address public tokenAddress;
    address public factoryAddress;

    constructor(address _token) ERC20("v1", "v1") {
        require(_token != address(0), "invalid token address");

        tokenAddress = _token;
        factoryAddress = msg.sender;
    }

    function addLiquidity(
        uint256 _tokenAmount
    ) public payable returns (uint256) {
        uint256 tokenReserve = getReserve();
        IERC20 token = IERC20(tokenAddress);
        //if liquide is not established
        if (tokenReserve == 0) {
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            uint256 liquidity = address(this).balance; //get LP token
            _mint(msg.sender, liquidity);
            return liquidity;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve; // following the first Reserve ratio
            require(tokenAmount <= _tokenAmount, "insufficient token amount");
            token.transferFrom(msg.sender, address(this), tokenAmount);
            uint256 liquidity = (totalSupply() * msg.value) / ethReserve; //get LP token
            _mint(msg.sender, liquidity);
            return liquidity;
        }
    }

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getPrice(
        uint256 inputReserve,
        uint256 ouputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && ouputReserve > 0, "invalid reserve");
        return (inputReserve * 1000) / ouputReserve;
    }

    /**
    
    Δy= (yΔx)/(x+Δx) 
    ​
     */
    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        //return (((inputAmount * outputReserve)) / (inputReserve + inputAmount));

        return numerator / denominator;
    }

    function getTokenAmount(uint256 ethSold) public view returns (uint256) {
        require(ethSold > 0, "ethSold is too small");
        uint256 tokenReserve = getReserve();
        return getAmount(ethSold, address(this).balance, tokenReserve);
    }
    function getETHAmount(uint256 tokenSold) public view returns (uint256) {
        require(tokenSold > 0, "tokenSold is too small");
        uint256 tokenReserve = getReserve();
        return getAmount(tokenSold, tokenReserve, address(this).balance);
    }

    function ethToToken(uint256 _minTokens, address recipient) private {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "insufficient output amount");
        IERC20(tokenAddress).transfer(recipient, tokensBought);
    }
    function ethToTokenSwap(uint256 _minTokens) public payable {
        ethToToken(_minTokens, msg.sender);
    }

    function ethToTokenTransfer(
        uint256 _minTokens,
        address _recipient
    ) public payable {
        ethToToken(_minTokens, _recipient);
    }

    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "insufficient output amount");

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        payable(msg.sender).transfer(ethBought);
    }

    function removeLiquidity(
        uint256 _amount
    ) public returns (uint256, uint256) {
        require(_amount > 0, "invalid amount");
        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
    }

    function tokenToTokenSwap(
        uint256 _tokensSold,
        uint256 _minTokenBought,
        address _tokenAddress
    ) public {
        address exchangeAddress = IFactory(factoryAddress).getExchange(
            _tokenAddress
        );

        require(
            exchangeAddress != address(0) && exchangeAddress != address(this),
            "invalid exchage address"
        );

        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        IExchange(exchangeAddress).ethToTokenTransfer{value: ethBought}(
            _minTokenBought,
            msg.sender
        );
    }
}
