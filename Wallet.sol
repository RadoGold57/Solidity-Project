// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract SampleWallet {
    address payable owner;

    mapping(address => uint) public  allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardian;
    address payable nextOwner;
    uint guardianResetCount;
    uint public constant confirmationFromGuardiansForReset = 3;

    constructor() {
        owner = payable(msg.sender);
    }

    function proposeNewOwner(address payable newOwner) public {
        require(guardian[msg.sender], "You are no guardian, Aborting");
        if(nextOwner != newOwner) {
            nextOwner = newOwner; 
            guardianResetCount =0;
        }

        guardianResetCount++;

        if(guardianResetCount >= confirmationFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance(address _from, uint _amount) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        allowance[_from] = _amount;
        isAllowedToSend[_from] = true;
    }

    function denySending(address _from) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        isAllowedToSend[_from] = false;
    }

    function transfer(address payable _to, uint _amount, bytes memory payload) public returns (bytes memory) {
        require(_amount <= address(this).balance, "Can't send more than the contract owns, aborting.");
        if(msg.sender != owner) {
            require(isAllowedToSend[msg.sender], "You are not allowed to send any transactions, aborting");
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to, aborting");
            allowance[msg.sender] -= _amount;

        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(payload);
        require(success, "Transaction failed, aborting");
        return returnData;
    }

    receive() external payable {}
}