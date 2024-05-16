// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing necessary OpenZeppelin contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AIStarterPublicSale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // IDO token address
    IERC20 public rewardToken;
    // IDO token price
    uint256 public joinIdoPrice;
    // max token Amount for IDO
    uint256 public rewardAmount;
    // default false
    bool public mbStart;
    // default no whitelist
    bool public mbWhiteAddr;
    // public sale opening time
    uint256 public startTime;
    // endTime = startTime + dt;
    uint256 public dt = 39 * 3600;
    // first claim = endtime + claimDt1
    uint256 public claimDt1;
    // first claim = endtime + claimDt2
    uint256 public claimDt2;
    // first claim = endtime + claimDt3
    uint256 public claimDt3;
    // max buy amount per user
    uint256 public maxAmountPerUser;
    // expect amount that user can get (will modify if over funded) 
    mapping(address => uint256) private _balance;
    // total participant
    uint256 private _addrAmount;
    // user buy amount (if > rewardAmount ,then is over funded)
    uint256 private _sumAmount;

    mapping(address => bool) private _isWhiteAddrArr;
    mapping(address => uint256) private _alreadyClaimNumArr;
    mapping(address => bool) private _bClaimBTC;
    address[] private _WhiteAddrArr;
    struct sJoinIdoPropertys {
        address addr;
        uint256 joinIdoAmount;
        uint256 time;
    }
    mapping(uint256 => sJoinIdoPropertys) private _joinIdoPropertys;
    uint256 private _sumCount;

    event JoinIdoCoins(address indexed user, uint256 amount, uint256 id);
    address public mFundAddress;

    constructor(
        address _rewardToken,
        uint256 _joinIdoPrice,
        uint256 _rewardAmount,
        address _mFundAddress
    ) {
        joinIdoPrice = _joinIdoPrice;
        rewardAmount = _rewardAmount;
        // default claim time can be modify if needed
        claimDt1 = dt + 3 * 3600;
        claimDt2 = claimDt1 + 0 * 24 * 3600;
        claimDt3 = claimDt1 + 0 * 24 * 3600;

        rewardToken = IERC20(_rewardToken);
        mFundAddress = _mFundAddress;
    }

    /* ========== VIEWS ========== */
    function sumCount() external view returns (uint256) {
        return _sumCount;
    }

    function sumAmount() external view returns (uint256) {
        return _sumAmount;
    }

    function addrAmount() external view returns (uint256) {
        return _addrAmount;
    }

    function balanceof(address account) external view returns (uint256) {
        return _balance[account];
    }

    function claimTokenNum(address account) external view returns (uint256) {
        return _alreadyClaimNumArr[account];
    }

    function bClaimBTC(address account) external view returns (bool) {
        return _bClaimBTC[account];
    }

    //read ido info
    function joinIdoInfo(uint256 iD)
        external
        view
        returns (
            address addr,
            uint256 joinIdoAmount,
            uint256 time
        )
    {
        require(iD <= _sumCount, "AINNStarterPublicSale: exist num!");
        addr = _joinIdoPropertys[iD].addr;
        joinIdoAmount = _joinIdoPropertys[iD].joinIdoAmount;
        time = _joinIdoPropertys[iD].time;
        return (addr, joinIdoAmount, time);
    }
    //read ido infos
    function joinIdoInfos(uint256 fromId, uint256 toId)
        external
        view
        returns (
            address[] memory addrArr,
            uint256[] memory joinIdoAmountArr,
            uint256[] memory timeArr
        )
    {
        require(toId <= _sumCount, "AINNStarterPublicSale: exist num!");
        require(fromId <= toId, "AINNStarterPublicSale: exist num!");
        addrArr = new address[](toId - fromId + 1);
        joinIdoAmountArr = new uint256[](toId - fromId + 1);
        timeArr = new uint256[](toId - fromId + 1);
        uint256 i = 0;
        for (uint256 ith = fromId; ith <= toId; ith++) {
            addrArr[i] = _joinIdoPropertys[ith].addr;
            joinIdoAmountArr[i] = _joinIdoPropertys[ith].joinIdoAmount;
            timeArr[i] = _joinIdoPropertys[ith].time;
            i = i + 1;
        }
        return (addrArr, joinIdoAmountArr, timeArr);
    }

    //check is whitelist ot not
    function isWhiteAddr(address account) public view returns (bool) {
        return _isWhiteAddrArr[account];
    }

    //get total whitelist amount
    function getWhiteAccountNum() public view returns (uint256) {
        return _WhiteAddrArr.length;
    }

    // get ith whitelist address
    function getWhiteAccountIth(uint256 ith)
        public
        view
        returns (address WhiteAddress)
    {
        require(
            ith < _WhiteAddrArr.length,
            "AINNStarterPublicSale: not in White Adress"
        );
        return _WhiteAddrArr[ith];
    }

    //get account amount (if over-funded then modify the amount)
    function getExpectedAmount(address account) public view returns (uint256) {
        uint256 ExpectedAmount = _balance[account];
        if (ExpectedAmount == 0) return ExpectedAmount;
        // handle over-funded situation
        if (_sumAmount > rewardAmount) {
            ExpectedAmount = (rewardAmount * (ExpectedAmount)) / (_sumAmount);
        }
        return ExpectedAmount;
    }

    // get all parameters associated with account
    function getParameters(address account)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory paraList = new uint256[](uint256(16));
        paraList[0] = 0;
        if (mbStart) paraList[0] = 1;
        paraList[1] = startTime; //start Time
        paraList[2] = startTime + dt; //end Time
        paraList[3] = joinIdoPrice; //Token Price:
        paraList[4] = rewardAmount; //max reward Amount
        paraList[5] = _addrAmount; //Total Participants
        paraList[6] = _sumAmount; //Total Committed
        paraList[7] = _balance[account]; //You committed
        uint256 expectedAmount = getExpectedAmount(account);
        uint256 refundAmount = _balance[account] - expectedAmount;
        expectedAmount = expectedAmount / (10**18) - (joinIdoPrice);
        paraList[8] = expectedAmount; //Expected token Amount
        paraList[9] = refundAmount; //refund Amount
        paraList[10] = _alreadyClaimNumArr[account]; //Claim num
        paraList[11] = 0;
        if (_bClaimBTC[account]) paraList[11] = 1; //is Claim BTC

        uint256 coe = 0;
        if (block.timestamp > startTime + claimDt1) {
            if (_alreadyClaimNumArr[account] < 1) coe = 30;
        }

        if (block.timestamp > startTime + claimDt2) {
            if (_alreadyClaimNumArr[account] < 2) coe = coe + 30;
        }
        if (block.timestamp > startTime + claimDt3) {
            if (_alreadyClaimNumArr[account] < 3) coe = coe + 40;
        }
        paraList[12] = coe; //can claim ratio
        paraList[13] = (expectedAmount * coe) / 100; //can claim amount
        uint256 LastCoe = 0;
        if (_alreadyClaimNumArr[account] < 1) LastCoe = 30;
        if (_alreadyClaimNumArr[account] < 2) LastCoe = LastCoe + 30;
        if (_alreadyClaimNumArr[account] < 3) LastCoe = LastCoe + 40;
        paraList[14] = LastCoe; //last claim ratio
        paraList[15] = (expectedAmount * LastCoe) / 100; //last claim amount

        return paraList;
    }

    //---write---//
    //join Ido
    function joinIdo() external payable nonReentrant {
        require(mbStart, "AINNStarterPublicSale: not Start!");
        require(
            block.timestamp < startTime + dt,
            "AINNStarterPublicSale: already end!"
        );
        if (mbWhiteAddr)
            require(
                _isWhiteAddrArr[msg.sender],
                "AINNStarterPublicSale:Account  not in white list"
            );
        require(10**8 <= msg.value, "MerlinStarterPublicSale:value sent is too small");
        uint256 amount = msg.value;

        if (_balance[msg.sender] == 0) {
            _addrAmount = _addrAmount + 1;
        }
        _balance[msg.sender] = _balance[msg.sender] + amount;
        _sumAmount = _sumAmount + amount;

        _sumCount = _sumCount + 1;
        _joinIdoPropertys[_sumCount].addr = msg.sender;
        _joinIdoPropertys[_sumCount].joinIdoAmount = amount;
        _joinIdoPropertys[_sumCount].time = block.timestamp;

        emit JoinIdoCoins(msg.sender, amount, _sumCount);
    }

    //claim Token
    function claimToken() external nonReentrant {
        require(mbStart, "AINNStarterPublicSale: not Start!");
        require(
            block.timestamp > startTime + dt,
            "AINNStarterPublicSale: need end!"
        );
        if (mbWhiteAddr)
            require(
                _isWhiteAddrArr[msg.sender],
                "AINNStarterPublicSale:Account  not in white list"
            );
        require(_balance[msg.sender] > 0, "AINNStarterPublicSale:balance zero");
        require(
            block.timestamp > startTime + claimDt1,
            "AINNStarterPublicSale: need begin claim!"
        );
        require(
            _alreadyClaimNumArr[msg.sender] < 3,
            "AINNStarterPublicSale: already claim all!"
        );

        uint256 coe = 0;
        // can change coe if you want to change unlock amount
        if (_alreadyClaimNumArr[msg.sender] < 1) {
            coe = 30;
            _alreadyClaimNumArr[msg.sender] =
                _alreadyClaimNumArr[msg.sender] +
                1;
        }
        if (block.timestamp > startTime + claimDt2) {
            if (_alreadyClaimNumArr[msg.sender] < 2) {
                coe = coe + 30;
                _alreadyClaimNumArr[msg.sender] =
                    _alreadyClaimNumArr[msg.sender] +
                    1;
            }
        }
        if (block.timestamp > startTime + claimDt3) {
            if (_alreadyClaimNumArr[msg.sender] < 3) {
                coe = coe + 40;
                _alreadyClaimNumArr[msg.sender] =
                    _alreadyClaimNumArr[msg.sender] +
                    1;
            }
        }

        require(coe > 0, "AINNStarterPublicSale: claim 0!");

        uint256 expectedAmount = getExpectedAmount(msg.sender);
        expectedAmount = (expectedAmount * (coe)) / (100);

        expectedAmount = (expectedAmount * 10**18) / joinIdoPrice;
        if (expectedAmount > 0)
            rewardToken.safeTransfer(msg.sender, expectedAmount);
    }

    //claim btc
    function claimBTC() external nonReentrant {
        require(mbStart, "AINNStarterPublicSale: not Start!");
        require(
            block.timestamp > startTime + dt,
            "AINNStarterPublicSale: need end!"
        );
        if (mbWhiteAddr)
            require(
                _isWhiteAddrArr[msg.sender],
                "AINNStarterPublicSale:Account  not in white list"
            );
        require(_balance[msg.sender] > 0, "AINNStarterPublicSale:balance zero");
        require(
            !_bClaimBTC[msg.sender],
            "AINNStarterPublicSale:already claim btc"
        );

        uint256 expectedAmount = getExpectedAmount(msg.sender);
        uint256 refundAmount = _balance[msg.sender] - (expectedAmount);
        _bClaimBTC[msg.sender] = true;
        if (refundAmount > 0) payable(msg.sender).transfer(refundAmount);
    }

    //---write onlyOwner---//
    function setParameters(
        address rewardTokenAddr,
        uint256 joinIdoPrice0,
        uint256 rewardAmount0
    ) external onlyOwner {
        require(!mbStart, "AINNStarterPublicSale: already Start!");
        rewardToken = IERC20(rewardTokenAddr);

        joinIdoPrice = joinIdoPrice0;
        rewardAmount = rewardAmount0;
    }

    function setStart(bool bstart) external onlyOwner {
        mbStart = bstart;
        startTime = block.timestamp;
    }

    // set Time
    function setDt(
        uint256 tDt,
        uint256 tDt1,
        uint256 tDt2,
        uint256 tDt3
    ) external onlyOwner {
        dt = tDt;
        claimDt1 = tDt1;
        claimDt2 = tDt2;
        claimDt3 = tDt3;
    }

    //setwhiteaddress true/false
    function setbWhiteAddr(bool bWhiteAddr) external onlyOwner {
        require(!mbStart, "AINNStarterPublicSale: already Start!");
        mbWhiteAddr = bWhiteAddr;
    }

    receive() external payable {}

    function withdraw(uint256 amount) external {
        require(msg.sender == mFundAddress, "AINNStarterPublicSale: not mFundAddress");
        (bool success, ) = payable(mFundAddress).call{value: amount}("");
        require(success, "Low-level call failed");
    }

    function withdrawToken(address tokenAddr, uint256 amount)
        external
        onlyOwner
    {
        IERC20 token = IERC20(tokenAddr);
        token.safeTransfer(mFundAddress, amount);
    }

    function addWhiteAccount(address account) external onlyOwner {
        require(
            !_isWhiteAddrArr[account],
            "AINNStarterPublicSale:Account is already in White list"
        );
        _isWhiteAddrArr[account] = true;
        _WhiteAddrArr.push(account);
    }

    function addWhiteAccount(address[] calldata accountArr) external onlyOwner {
        for (uint256 i = 0; i < accountArr.length; ++i) {
            require(
                !_isWhiteAddrArr[accountArr[i]],
                "AINNStarterPublicSale:Account is already in White list"
            );
            _isWhiteAddrArr[accountArr[i]] = true;
            _WhiteAddrArr.push(accountArr[i]);
        }
    }

    function removeWhiteAccount(address account) external onlyOwner {
        require(
            _isWhiteAddrArr[account],
            "AINNStarterPublicSale:Account is already out White list"
        );
        for (uint256 i = 0; i < _WhiteAddrArr.length; i++) {
            if (_WhiteAddrArr[i] == account) {
                _WhiteAddrArr[i] = _WhiteAddrArr[_WhiteAddrArr.length - 1];
                _WhiteAddrArr.pop();
                _isWhiteAddrArr[account] = false;
                break;
            }
        }
    }
}