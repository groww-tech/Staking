// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking {
    using SafeERC20 for IERC20;

    uint256 constant SECONDS_IN_DAY = 86400;
    uint256 constant STAKE_REWARD = 1e21;
    uint256 constant REWARD = 1e18;

    struct UserInfo {
        uint256 amount;
        uint256 rewards;
        uint256 lastUpdateTime;
    }

    mapping(address => UserInfo) public userInfo;

    IERC20 public token;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 rewards);

    constructor(IERC20 _token) {
        token = _token;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "zero amount");
        UserInfo storage user = userInfo[msg.sender];
        updateRewards(user);
        user.amount += amount;
        user.lastUpdateTime = block.timestamp;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "zero staked");
        updateRewards(user);
        uint256 totalAmount = user.amount + user.rewards;
        delete userInfo[msg.sender];

        token.safeTransfer(msg.sender, totalAmount);
        emit Withdrawn(msg.sender, user.amount, user.rewards);
    }

    function updateRewards(UserInfo storage user) internal {
        if (user.amount == 0) {
            return;
        }

        uint256 currentTime = block.timestamp;
        uint256 lastUpdateTime = user.lastUpdateTime;

        if (currentTime > lastUpdateTime) {
            uint256 elapsedTime = currentTime - lastUpdateTime;
            uint256 daysElapsed = elapsedTime / SECONDS_IN_DAY;

            if (daysElapsed > 0) {
                user.rewards +=
                    (user.amount * daysElapsed * REWARD) /
                    STAKE_REWARD;
                user.lastUpdateTime = currentTime;
            }
        }
    }
}
