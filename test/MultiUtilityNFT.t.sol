// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console, Vm} from "forge-std/Test.sol";
import {MultiUtilityNFT} from "../src/MultiUtilityNFT.sol";
import {PaymentToken} from "../src/PaymentToken.sol";
import {ISablierLockup} from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

contract MultiUtilityNFTTest is Test {
    uint256 public constant DISCOUNT_PRICE = 1 ether;
    uint256 public constant FULL_PRICE = 2 ether;
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    MultiUtilityNFT public multiUtilityNFT;
    PaymentToken public paymentToken;
    address public owner;
    address[] public users;

    bytes32[] public phase1MerkleTreeLeaves;
    bytes32[] public phase2MerkleTreeLeaves;
    bytes32 public phase1MerkleRoot;
    bytes32 public phase2MerkleRoot;

    function setUp() public {
        // Store an address for the owner and 20 users
        owner = (vm.createWallet(vm.randomUint())).addr;
        for (uint256 i = 0; i < 20; i++) {
            users.push((vm.createWallet(vm.randomUint())).addr);
        }

        // Generate two merkle trees for the two phases
        for (uint256 i = 0; i < 10; i++) {
            phase1MerkleTreeLeaves.push(keccak256(abi.encodePacked(users[i])));
            phase2MerkleTreeLeaves.push(keccak256(abi.encodePacked(users[i + 10])));
        }
        phase1MerkleRoot = computeMerkleRoot(phase1MerkleTreeLeaves);
        phase2MerkleRoot = computeMerkleRoot(phase2MerkleTreeLeaves);

        // Deploy the contracts
        paymentToken = new PaymentToken();
        multiUtilityNFT = new MultiUtilityNFT(
            owner,
            ISablierLockup(address(1)),
            paymentToken,
            DISCOUNT_PRICE,
            FULL_PRICE,
            phase1MerkleRoot,
            phase2MerkleRoot,
            block.timestamp + 1 days,
            block.timestamp + 2 days,
            block.timestamp + 3 days
        );

        // Mint some tokens for the users
        paymentToken.mint(owner, INITIAL_SUPPLY);
        for (uint256 i = 0; i < 20; i++) {
            paymentToken.mint(users[i], INITIAL_SUPPLY);
        }
    }

    function testConstructorParameters() public view {
        assertEq(multiUtilityNFT.owner(), owner);
        assertEq(address(multiUtilityNFT.sablierLockup()), address(1));
        assertEq(address(multiUtilityNFT.paymentToken()), address(paymentToken));
        assertEq(multiUtilityNFT.discountPrice(), DISCOUNT_PRICE);
        assertEq(multiUtilityNFT.fullPrice(), FULL_PRICE);
        assertEq(multiUtilityNFT.phase1MerkleRoot(), phase1MerkleRoot);
        assertEq(multiUtilityNFT.phase2MerkleRoot(), phase2MerkleRoot);
        assertEq(multiUtilityNFT.phase1EndTimestamp(), block.timestamp + 1 days);
        assertEq(multiUtilityNFT.phase2EndTimestamp(), block.timestamp + 2 days);
        assertEq(multiUtilityNFT.phase3EndTimestamp(), block.timestamp + 3 days);
    }

    function computeMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        require(leaves.length > 0, "No leaves provided");

        while (leaves.length > 1) {
            uint256 newLength = (leaves.length + 1) / 2;
            bytes32[] memory newLeaves = new bytes32[](newLength);

            for (uint256 i = 0; i < newLength; i++) {
                bytes32 left = leaves[i * 2];
                bytes32 right = (i * 2 + 1 < leaves.length) ? leaves[i * 2 + 1] : left; // If odd, duplicate last element

                newLeaves[i] = keccak256(abi.encodePacked(left, right));
            }

            leaves = newLeaves;
        }

        return leaves[0]; // The Merkle root
    }
}
