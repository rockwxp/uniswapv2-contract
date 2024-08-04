// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import "../src/V1/uniswap_v1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Uniswapv1Test is Test {
    Token public token;
    Exchange public exchange;
    address public msgSender;

    function setUp() public {
        msgSender = vm.addr(
            uint256(keccak256(abi.encodePacked("randomUser", block.timestamp)))
        );
        vm.startPrank(msgSender);
        vm.deal(msgSender, 100 ether);
        token = new Token("T", "t_1", 100 * 1e18);
        exchange = new Exchange(address(token));
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(msgSender);
        token.approve(address(exchange), 200);
        exchange.addLiquidity{value: 100}(200);
        uint256 tokenReserve = exchange.getReserve();
        console.log("getReserve", tokenReserve);
        assertEq(exchange.getReserve(), 200);
        vm.stopPrank();
    }
    function testGetPrice() public {
        vm.startPrank(msgSender);
        token.approve(address(exchange), 2000);
        exchange.addLiquidity{value: 1000}(2000);
        uint256 tokenReserve = exchange.getReserve();
        uint256 ethReserve = address(exchange).balance;
        console.log("Token Reserve:", tokenReserve);
        console.log("ETH   Reserve:", ethReserve);
        console.log("eth/token:", exchange.getPrice(ethReserve, tokenReserve));
        console.log("token/eth:", exchange.getPrice(tokenReserve, ethReserve));
        vm.stopPrank();
    }

    function testGetAmount() public {
        vm.startPrank(msgSender);
        token.approve(address(exchange), 2000);
        exchange.addLiquidity{value: 1000}(2000);
        uint256 tokenReserve = exchange.getReserve();
        uint256 ethReserve = address(exchange).balance;
        console.log("Token Reserve:", tokenReserve);
        console.log("ETH   Reserve:", ethReserve);
        console.log("eth/token:", exchange.getPrice(ethReserve, tokenReserve));
        console.log("token/eth:", exchange.getPrice(tokenReserve, ethReserve));

        uint256 tokenAmount = exchange.getTokenAmount(1000);
        console.log("tokenOut:", tokenAmount);
        uint256 ethAmount = exchange.getETHAmount(2000);
        console.log("ethOut:", ethAmount);
        vm.stopPrank();
    }

    function testSwap() public {
        vm.startPrank(msgSender);
        token.approve(address(exchange), 2000);
        exchange.addLiquidity{value: 100}(200);
        uint256 tokenReserve = exchange.getReserve();
        uint256 ethReserve = address(exchange).balance;
        uint256 lpTokenSupply = IERC20(address(exchange)).totalSupply();
        uint256 lpToken = IERC20(address(exchange)).balanceOf(msgSender);
        console.log("Token Reserve:", tokenReserve);
        console.log("ETH   Reserve:", ethReserve);
        console.log("LP Token TotalSupply: ", lpTokenSupply);
        console.log("LP Token msg.sender: ", lpToken);
        console.log("eth/token:", exchange.getPrice(ethReserve, tokenReserve));
        console.log("token/eth:", exchange.getPrice(tokenReserve, ethReserve));

        uint256 tokenAmount = exchange.getTokenAmount(100);
        console.log("tokenOut:", tokenAmount);
        uint256 ethAmount = exchange.getETHAmount(200);
        console.log("ethOut:", ethAmount);
        vm.stopPrank();
    }
}
