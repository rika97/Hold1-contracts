// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hold1 {
    address public owner;
    uint256 public constant NEW_USER_TOKENS = 1000 * 1e18;
    uint256 public constant FRIEND_BONUS_TOKENS = 500 * 1e18;
    uint256 public constant TASK_BONUS_TOKENS = 200 * 1e18;
    uint256 public constant PRICE_TARGET_PERCENTAGE = 10;
    uint256 public constant TIME_LIMIT = 30 minutes;

    struct Train {
        address[] users;
        uint256 startTime;
        uint256 startPrice;
        uint256 totalTokens;
    }

    mapping(address => uint256) public balances;
    mapping(uint256 => Train) public trains;
    uint256 public nextTrainId;
    uint256 public jackpot;

    event TrainStarted(uint256 trainId, address starter);
    event TrainJoined(uint256 trainId, address user);
    event TrainWon(uint256 trainId, address winner, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function registerUser(address newUser) external onlyOwner {
        require(balances[newUser] == 0, "User already registered");
        balances[newUser] = NEW_USER_TOKENS;
    }

    function addFriend(address user, address friend) external onlyOwner {
        require(balances[user] > 0, "User not registered");
        require(balances[friend] > 0, "Friend not registered");
        balances[user] += FRIEND_BONUS_TOKENS;
        balances[friend] += FRIEND_BONUS_TOKENS;
    }

    function completeTask(address user) external onlyOwner {
        require(balances[user] > 0, "User not registered");
        balances[user] += TASK_BONUS_TOKENS;
    }

    function startTrain() external {
        require(balances[msg.sender] > 0, "User not registered");
        Train storage train = trains[nextTrainId++];
        train.users.push(msg.sender);
        train.startTime = block.timestamp;
        train.startPrice = getCurrentPrice();
        train.totalTokens += balances[msg.sender];
        balances[msg.sender] = 0;

        emit TrainStarted(nextTrainId - 1, msg.sender);
    }

    function joinTrain(uint256 trainId) external {
        require(balances[msg.sender] > 0, "User not registered");
        Train storage train = trains[trainId];
        require(block.timestamp < train.startTime + TIME_LIMIT, "Time limit exceeded");
        train.users.push(msg.sender);
        train.totalTokens += balances[msg.sender];
        balances[msg.sender] = 0;

        emit TrainJoined(trainId, msg.sender);
    }

    function checkTrain(uint256 trainId) external {
        Train storage train = trains[trainId];
        require(block.timestamp >= train.startTime + TIME_LIMIT, "Time limit not exceeded");
        uint256 currentPrice = getCurrentPrice();
        if (currentPrice >= train.startPrice + (train.startPrice * PRICE_TARGET_PERCENTAGE / 100)) {
            // Train won
            address winner = train.users[random() % train.users.length];
            uint256 reward = train.totalTokens / 2;
            balances[winner] += reward;
            balances[owner] += train.totalTokens - reward;
            emit TrainWon(trainId, winner, reward);
        } else {
            // Train lost
            jackpot += train.totalTokens;
        }
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nextTrainId)));
    }

    function getCurrentPrice() private view returns (uint256) {
        // Implement actual price fetching logic here
        return 100; // Placeholder
    }
}
