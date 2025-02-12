// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console, Vm} from "forge-std/Test.sol";
import {MultiUtilityNFT} from "../src/MultiUtilityNFT.sol";
import {PaymentToken} from "../src/PaymentToken.sol";
import {CompleteMerkle} from "@dmfxyz/murky/src/CompleteMerkle.sol";
import {ISablierLockup} from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MultiUtilityNFTTest is Test {
    uint256 constant DISCOUNT_PRICE = 1 ether;
    uint256 constant FULL_PRICE = 2 ether;
    uint256 constant INITIAL_SUPPLY = 100 ether;

    MultiUtilityNFT multiUtilityNFT;
    PaymentToken paymentToken;
    Vm.Wallet owner;
    address ownerAddress;
    address[] usersPhase1;
    address[] usersPhase2;

    bytes32[] phase1MerkleTreeLeaves;
    bytes32[] phase2MerkleTreeLeaves;
    bytes32 phase1MerkleRoot;
    bytes32 phase2MerkleRoot;

    CompleteMerkle merkle = new CompleteMerkle();
    ISablierLockup sablierLockup = ISablierLockup(0x7C01AA3783577E15fD7e272443D44B92d5b21056);

    function setUp() public {
        // Store an address for the owner and users
        owner = vm.createWallet(vm.randomUint());
        ownerAddress = owner.addr;
        for (uint256 i = 0; i < 10; i++) {
            usersPhase1.push((vm.createWallet(vm.randomUint())).addr);
            usersPhase2.push((vm.createWallet(vm.randomUint())).addr);
        }

        // Generate two merkle trees for the two phases
        for (uint256 i = 0; i < 10; i++) {
            phase1MerkleTreeLeaves.push(keccak256(abi.encodePacked(usersPhase1[i])));
            phase2MerkleTreeLeaves.push(keccak256(abi.encodePacked(usersPhase2[i])));
        }
        phase1MerkleRoot = merkle.getRoot(phase1MerkleTreeLeaves);
        phase2MerkleRoot = merkle.getRoot(phase2MerkleTreeLeaves);

        // Deploy the contracts
        paymentToken = new PaymentToken();
        multiUtilityNFT = new MultiUtilityNFT(
            ownerAddress,
            sablierLockup,
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
        paymentToken.mint(ownerAddress, INITIAL_SUPPLY);
        for (uint256 i = 0; i < 10; i++) {
            paymentToken.mint(usersPhase1[i], INITIAL_SUPPLY);
            paymentToken.mint(usersPhase2[i], INITIAL_SUPPLY);
        }
    }

    function testConstructorParameters() public view {
        assertEq(multiUtilityNFT.owner(), ownerAddress);
        assertEq(address(multiUtilityNFT.sablierLockup()), address(sablierLockup));
        assertEq(address(multiUtilityNFT.paymentToken()), address(paymentToken));
        assertEq(multiUtilityNFT.discountPrice(), DISCOUNT_PRICE);
        assertEq(multiUtilityNFT.fullPrice(), FULL_PRICE);
        assertEq(multiUtilityNFT.phase1MerkleRoot(), phase1MerkleRoot);
        assertEq(multiUtilityNFT.phase2MerkleRoot(), phase2MerkleRoot);
        assertEq(multiUtilityNFT.phase1EndTimestamp(), block.timestamp + 1 days);
        assertEq(multiUtilityNFT.phase2EndTimestamp(), block.timestamp + 2 days);
        assertEq(multiUtilityNFT.phase3EndTimestamp(), block.timestamp + 3 days);
    }

    function testGetCurrentPhase() public {
        uint256 currentTimestamp = block.timestamp;

        assert(multiUtilityNFT.getCurrentPhase() == MultiUtilityNFT.Phase.Phase1);
        vm.warp(currentTimestamp + 1 days + 1 seconds);
        assert(multiUtilityNFT.getCurrentPhase() == MultiUtilityNFT.Phase.Phase2);
        vm.warp(currentTimestamp + 2 days + 1 seconds);
        assert(multiUtilityNFT.getCurrentPhase() == MultiUtilityNFT.Phase.Phase3);
        vm.warp(currentTimestamp + 3 days + 1 seconds);
        assert(multiUtilityNFT.getCurrentPhase() == MultiUtilityNFT.Phase.Finished);
    }

    // ----------- Phase 1 Tests -----------------------------------------------

    function testMintPhase1Ok() public {
        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase1[i]);
            assert(!multiUtilityNFT.phase1Claimed(usersPhase1[i]));
            uint256 balance = multiUtilityNFT.balanceOf(usersPhase1[i]);

            bytes32[] memory proof = merkle.getProof(phase1MerkleTreeLeaves, i);
            multiUtilityNFT.mintPhase1(proof);
            assert(multiUtilityNFT.phase1Claimed(usersPhase1[i]));
            assertEq(multiUtilityNFT.balanceOf(usersPhase1[i]), balance + 1);
            vm.stopPrank();
        }
    }

    function testMintPhase1AlreadyClaimed() public {
        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase1[i]);
            bytes32[] memory proof = merkle.getProof(phase1MerkleTreeLeaves, i);

            multiUtilityNFT.mintPhase1(proof);
            assert(multiUtilityNFT.phase1Claimed(usersPhase1[i]));

            vm.expectRevert(MultiUtilityNFT.AlreadyClaimed.selector);
            multiUtilityNFT.mintPhase1(proof);
            vm.stopPrank();
        }
    }

    function testMintPhase1InvalidPhase() public {
        // Warp to the end of the first phase
        vm.warp(block.timestamp + 1 days + 1 seconds);

        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase1[i]);
            bytes32[] memory proof = merkle.getProof(phase1MerkleTreeLeaves, i);

            vm.expectRevert(MultiUtilityNFT.InvalidPhase.selector);
            multiUtilityNFT.mintPhase1(proof);
            vm.stopPrank();
        }
    }

    function testMintPhase1InvalidProof() public {
        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase1[i]);
            bytes32[] memory proof = merkle.getProof(phase1MerkleTreeLeaves, i);
            proof[0] = keccak256(abi.encodePacked(usersPhase1[i]));
            vm.expectRevert(MultiUtilityNFT.InvalidProof.selector);
            multiUtilityNFT.mintPhase1(proof);
            vm.stopPrank();
        }
    }

    // ----------- Phase 2 Tests -----------------------------------------------

    function testMintPhase2Ok() public {
        // Warp to the second phase
        vm.warp(block.timestamp + 1 days + 1 seconds);

        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase2[i]);
            assert(!multiUtilityNFT.phase2Claimed(usersPhase2[i]));
            uint256 balance = multiUtilityNFT.balanceOf(usersPhase2[i]);
            uint256 balanceNftBefore = paymentToken.balanceOf(address(multiUtilityNFT));

            paymentToken.approve(address(multiUtilityNFT), multiUtilityNFT.discountPrice());

            bytes memory signature = generateSignature(usersPhase2[i]);
            bytes32[] memory proof = merkle.getProof(phase2MerkleTreeLeaves, i);
            multiUtilityNFT.mintPhase2(signature, proof);
            assert(multiUtilityNFT.phase2Claimed(usersPhase2[i]));
            assertEq(multiUtilityNFT.balanceOf(usersPhase2[i]), balance + 1);
            assertEq(paymentToken.balanceOf(address(multiUtilityNFT)), balanceNftBefore + DISCOUNT_PRICE);
            vm.stopPrank();
        }
    }

    function testMintPhase2AlreadyClaimed() public {
        // Warp to the second phase
        vm.warp(block.timestamp + 1 days + 1 seconds);

        // Mint NFTs for the first 10 users
        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase2[i]);
            paymentToken.approve(address(multiUtilityNFT), multiUtilityNFT.discountPrice());
            bytes memory signature = generateSignature(usersPhase2[i]);
            bytes32[] memory proof = merkle.getProof(phase2MerkleTreeLeaves, i);
            multiUtilityNFT.mintPhase2(signature, proof);

            assert(multiUtilityNFT.phase2Claimed(usersPhase2[i]));

            vm.expectRevert(MultiUtilityNFT.AlreadyClaimed.selector);
            multiUtilityNFT.mintPhase2(signature, proof);
            vm.stopPrank();
        }
    }

    function testMintPhase2InvalidPhase() public {
        // Warp to the end of the second phase
        vm.warp(block.timestamp + 2 days + 1 seconds);

        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase2[i]);
            paymentToken.approve(address(multiUtilityNFT), multiUtilityNFT.discountPrice());
            bytes memory signature = generateSignature(usersPhase2[i]);
            bytes32[] memory proof = merkle.getProof(phase2MerkleTreeLeaves, i);

            vm.expectRevert(MultiUtilityNFT.InvalidPhase.selector);
            multiUtilityNFT.mintPhase2(signature, proof);
            vm.stopPrank();
        }
    }

    function testMintPhase2InvalidProof() public {
        // Warp to the second phase
        vm.warp(block.timestamp + 1 days + 1 seconds);

        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase2[i]);
            paymentToken.approve(address(multiUtilityNFT), multiUtilityNFT.discountPrice());
            bytes memory signature = generateSignature(usersPhase2[i]);
            bytes32[] memory proof = merkle.getProof(phase2MerkleTreeLeaves, i);
            proof[0] = keccak256(abi.encodePacked(usersPhase2[i]));

            vm.expectRevert(MultiUtilityNFT.InvalidProof.selector);
            multiUtilityNFT.mintPhase2(signature, proof);
            vm.stopPrank();
        }
    }

    function testMintPhase2InvalidSignature() public {
        // Warp to the second phase
        vm.warp(block.timestamp + 1 days + 1 seconds);

        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase2[i]);
            paymentToken.approve(address(multiUtilityNFT), multiUtilityNFT.discountPrice());
            bytes memory signature = generateSignature(usersPhase1[i]);
            bytes32[] memory proof = merkle.getProof(phase2MerkleTreeLeaves, i);

            vm.expectRevert(MultiUtilityNFT.InvalidSignature.selector);
            multiUtilityNFT.mintPhase2(signature, proof);
            vm.stopPrank();
        }
    }

    // ----------- Phase 3 Tests -----------------------------------------------

    function testMintPhase3Ok() public {
        // Warp to the third phase
        vm.warp(block.timestamp + 2 days + 1 seconds);

        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase1[i]);
            uint256 balance = multiUtilityNFT.balanceOf(usersPhase1[i]);
            uint256 balanceNftBefore = paymentToken.balanceOf(address(multiUtilityNFT));

            paymentToken.approve(address(multiUtilityNFT), multiUtilityNFT.fullPrice());

            multiUtilityNFT.mintPhase3();
            assertEq(multiUtilityNFT.balanceOf(usersPhase1[i]), balance + 1);
            assertEq(paymentToken.balanceOf(address(multiUtilityNFT)), balanceNftBefore + FULL_PRICE);
            vm.stopPrank();
        }
    }

    function testMintPhase3InvalidPhase() public {
        // Warp to the end of the third phase
        vm.warp(block.timestamp + 3 days + 1 seconds);

        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(usersPhase1[i]);
            paymentToken.approve(address(multiUtilityNFT), multiUtilityNFT.fullPrice());

            vm.expectRevert(MultiUtilityNFT.InvalidPhase.selector);
            multiUtilityNFT.mintPhase3();
            vm.stopPrank();
        }
    }

    // ----------- Test Sablier Lockup -----------------------------------------

    function testLockMintingFundsOnSablierNonOwner() public {
        // Warp to the end of the third phase
        vm.warp(block.timestamp + 3 days + 1 seconds);

        vm.startPrank(usersPhase1[0]);
        vm.expectRevert();
        multiUtilityNFT.lockMintingFundsOnSablier();
        vm.stopPrank();
    }

    function testLockMintingFundsOnSablierInvalidPhase() public {
        // Warp to before of the end of the third phase
        vm.warp(block.timestamp + 3 days - 1 seconds);

        vm.startPrank(ownerAddress);
        vm.expectRevert(MultiUtilityNFT.InvalidPhase.selector);
        multiUtilityNFT.lockMintingFundsOnSablier();
        vm.stopPrank();
    }

    // ----------- Helper Functions --------------------------------------------

    function generateSignature(address account) public view returns (bytes memory) {
        // Generate the signature
        bytes32 hash = keccak256(
            abi.encode(
                keccak256("MultiUtilityNFT(uint256 chainid, address nft, address account)"),
                block.chainid,
                address(multiUtilityNFT),
                account
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator(), hash));

        // Sign the digest using a private key (assumes you have a signing mechanism)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner.privateKey, digest);

        // Return the signature
        return abi.encodePacked(r, s, v);
    }

    // Compute domain separator for EIP712
    function domainSeparator() internal view returns (bytes32) {
        bytes32 EIP712_DOMAIN_TYPEHASH =
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        return keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("MultiUtilityNFT")),
                keccak256(bytes("1")),
                block.chainid,
                multiUtilityNFT
            )
        );
    }
}
