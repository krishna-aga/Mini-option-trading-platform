// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Option {
    AggregatorV3Interface internal priceFeed;
    uint public id = 0;
    IERC20 public mockUSDT;
    mapping(address => mapping(uint => optionData)) public optionsWritten; //address to option id to optiondata(struct)

    event OptionCreated(
        uint indexed id,
        address indexed writer,
        uint256 strikePrice,
        uint256 premium,
        bool isCall
    );
    event OptionBought(uint indexed id, address indexed holder);
    event OptionExercised(
        uint indexed id,
        address indexed holder,
        uint256 profit,
        bool isCall
    );

    constructor(address _address) {
        priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        mockUSDT = IERC20(_address);
    }

    struct optionData {
        uint id;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiration;
        address writer;
        address holder;
        bool isActive;
        bool isCall;
        uint collateral;
    }

    function createOption(
        uint256 _strikePrice,
        uint256 _premium,
        uint256 _expiration,
        bool _isCall
    ) public returns (optionData memory) {
        bool success = mockUSDT.transferFrom(
            msg.sender,
            address(this),
            _strikePrice
        );
        require(success, "Transfer failed");
        id++;

        optionData memory newOption = optionData({
            id: id,
            strikePrice: _strikePrice,
            premium: _premium,
            expiration: _expiration,
            writer: msg.sender,
            holder: address(0),
            isActive: true,
            isCall: _isCall,
            collateral: _strikePrice
        });
        optionsWritten[msg.sender][id] = newOption;
        emit OptionCreated(id, msg.sender, _strikePrice, _premium, _isCall);


        return newOption;
    }

    function getPrice() public view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price) * 10 ** 10; // Convert 8 decimals → 18 decimals
    }

    function getOption(
        address writer,
        uint optionId
    ) public view returns (optionData memory) {
        return optionsWritten[writer][optionId];
    }

    function buyOption(address writer, uint optionId) public {
        optionData storage option = optionsWritten[writer][optionId];
        require(option.isActive, "Option is not active");
        require(option.holder == address(0), "Option already bought");
        require(block.timestamp < option.expiration, "Option has expired");

        bool success = mockUSDT.transferFrom(
            msg.sender,
            writer,
            option.premium
        );
        require(success, "Transfer failed");

        option.holder = msg.sender;
            emit OptionBought(optionId, msg.sender);

    }

function exerciseOption(address writer, uint optionId) public {
    optionData storage option = optionsWritten[writer][optionId];
    require(option.isActive, "Option is not active");
    require(option.holder == msg.sender, "Not the holder");
    require(block.timestamp < option.expiration, "Expired");

    uint256 currentPrice = getPrice();
    uint256 profit = 0;

    if (option.isCall) {
        uint256 diff = (currentPrice > option.strikePrice)
            ? currentPrice - option.strikePrice
            : 0;
        profit = diff > option.collateral ? option.collateral : diff;
        exerciseCallOption(option, currentPrice);
    } else {
        uint256 diff = (option.strikePrice > currentPrice)
            ? option.strikePrice - currentPrice
            : 0;
        profit = diff > option.collateral ? option.collateral : diff;
        exercisePutOption(option, currentPrice);
    }

    option.isActive = false;
    emit OptionExercised(optionId, msg.sender, profit, option.isCall);
}

    function exerciseCallOption(
        optionData memory option,
        uint256 currentPrice
    ) internal returns (bool) {
        if (currentPrice <= option.strikePrice) {
            bool success = mockUSDT.transfer(option.writer, option.collateral);
            return success;
        } else {
            uint256 profit = currentPrice - option.strikePrice;
            if (profit > option.collateral) {
                profit = option.collateral;
            }
            bool success = mockUSDT.transfer(option.holder, profit);
            bool success2 = mockUSDT.transfer(
                option.writer,
                option.collateral - profit
            );
            return (success && success2);
        }
    }

    function exercisePutOption(
        optionData memory option,
        uint256 currentPrice
    ) internal returns (bool) {
        if (currentPrice <= option.strikePrice) {
            uint256 profit = option.strikePrice - currentPrice;
            if (profit > option.collateral) {
                profit = option.collateral;
            }
            bool success = mockUSDT.transfer(option.holder, profit);
            bool success2 = mockUSDT.transfer(
                option.writer,
                option.collateral - profit
            );
            return (success && success2);
        } else {
            bool success = mockUSDT.transfer(option.writer, option.collateral);
            return success;
        }
    }
}
