pragma solidity ^0.4.14;

import "./LSTToken.sol";

contract Contribution is SafeMath, Owned {
    uint256 public constant MIN_FUND = (0.01 ether);
    uint256 public constant CRAWDSALE_START_DAY = 1;
    uint256 public constant CRAWDSALE_PRE_DAY = 50;
    uint256 public constant CRAWDSALE_END_DAY = 57;
    uint256 public constant decimals = 18;
    uint256 public constant ONE_COIN = 10**decimals;
    uint256 public constant MILLION = (10**6 * ONE_COIN);

    uint256 public constant CWK_1 = 15;
    uint256 public constant CWK_2 = 30;
    uint256 public constant CWK_3 = 50;
    uint256 public constant CRATE_1 = 5500*ONE_COIN;
    uint256 public constant CRATE_2 = 5000*ONE_COIN;
    uint256 public constant CRATE_3 = 4500*ONE_COIN;
    uint256 public constant CRATE_4 = 4000*ONE_COIN;

    LSTToken public lstToken;

    uint256 public icoSupply = 70 * MILLION;
    uint256 public devKeep = 30 * MILLION;
    uint256 public preSupply = 10 * MILLION;
    uint256 public icoAmount = 0;

    uint256 public dayCycle = 24 hours;
    uint256 public fundingStartTime = 1510272000; // 10/11/2017 UTC
    address public ethFundDeposit = 0;
    bool public isPause = false;
    uint256 public totalContributedETH = 0;

    // events
    event LogBuy (uint window, address user, uint amount, uint take);
    event LogCreate (address ethFundAddress, uint icoStartTime, uint dayWindow);
    event LogPause (uint finalizeTime, bool pause);

    function Contribution (address _ethFundDeposit)  {
        require(_ethFundDeposit != address(0));

        ethFundDeposit = _ethFundDeposit;

        lstToken = new LSTToken();
        lstToken.transferOwnership(ethFundDeposit);
        lstToken.transfer(ethFundDeposit, devKeep);

        LogCreate(ethFundDeposit, fundingStartTime, dayCycle);
    }

    //crawdsale entry
    function () payable {
        require(!isPause);
        require(msg.value >= MIN_FUND); //eth >= 0.01 at least

        buy(today(), msg.sender, msg.value);
        ethFundDeposit.transfer(msg.value);
    }

    function buy(uint256 day, address _addr, uint256 _amount) internal {
        require(day >= CRAWDSALE_START_DAY && day <= CRAWDSALE_END_DAY); 

        uint rate = CRATE_4;
        if (day <= CWK_1) {
            rate = CRATE_1;
        } else if (day <= CWK_2) {
            rate = CRATE_2;
        } else if (day <= CWK_3) {
            rate = CRATE_3;
        }

        uint take = wmul(_amount, rate);
        uint limit = icoSupply;
        if (day <= CRAWDSALE_PRE_DAY) {
            limit = preSupply;
        }
        icoAmount = add(icoAmount, take);
        assert(icoAmount <= limit);

        lstToken.transfer(_addr, take);

        totalContributedETH += _amount;
        LogBuy(day, _addr, _amount, take);
    }

    function recycle() onlyOwner {
        uint take = sub(icoSupply, icoAmount);
        lstToken.transfer(ethFundDeposit, take);
        icoAmount = icoSupply;
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }

    function pause(bool _isPause) onlyOwner {
        isPause = _isPause;
        LogPause(now,_isPause);
    }

    function today() constant returns (uint) {
        return sub(now, fundingStartTime) / dayCycle + 1;
    }
}
