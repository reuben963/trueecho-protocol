// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TrueEchoEscrow {
    
    struct ReviewEscrow {
        address merchant;
        uint256 rewardAmount;
        bool isRedeemed;
    }

    mapping(bytes32 => ReviewEscrow) public escrows;
    address public protocolValidatorNode;

    modifier onlyValidator() {
        require(msg.sender == protocolValidatorNode, "Only the network validator can execute this step.");
        _;
    }

    function lockReviewBounty(bytes32 _nullifierHash, uint256 _amount) external payable {
        require(msg.value == _amount, "Incorrect reward backing funds submitted.");
        require(escrows[_nullifierHash].merchant == address(0), "Transaction already has an active escrow.");

        escrows[_nullifierHash] = ReviewEscrow({
            merchant: msg.sender,
            rewardAmount: _amount,
            isRedeemed: false
        });
    }

    function executeReviewRelease(bytes32 _nullifierHash, address payable _reviewerWallet) external onlyValidator {
        ReviewEscrow storage escrow = escrows[_nullifierHash];
        
        require(!escrow.isRedeemed, "This transaction review token has already been claimed.");
        require(escrow.rewardAmount > 0, "No funds exist for this transaction profile.");

        escrow.isRedeemed = true;
        uint256 payout = escrow.rewardAmount;
        escrow.rewardAmount = 0;

        _reviewerWallet.transfer(payout);
    }
}