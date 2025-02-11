// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ISablierLockup} from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

error ZeroAddress();
error InvalidTimestamp();
error InvalidPhase();
error InvalidProof();
error InvalidSignature();
error AlreadyClaimed();

contract MultiUtilityNFT is ERC721, EIP712, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Phase {
        Phase1,
        Phase2,
        Phase3,
        Finished
    }

    ISablierLockup public immutable sablierLockup;
    IERC20 public immutable paymentToken;
    uint256 public immutable discountPrice;
    uint256 public immutable fullPrice;
    bytes32 public immutable phase1MerkleRoot;
    bytes32 public immutable phase2MerkleRoot;
    uint256 public immutable phase1EndTimestamp;
    uint256 public immutable phase2EndTimestamp;
    uint256 public immutable phase3EndTimestamp;

    mapping(address => bool) public phase1Claimed;
    mapping(address => bool) public phase2Claimed;

    uint256 internal nextTokenId;

    constructor(
        address _owner,
        ISablierLockup _sablierLockup,
        IERC20 _paymentToken,
        uint256 _discountPrice,
        uint256 _fullPrice,
        bytes32 _phase1MerkleRoot,
        bytes32 _phase2MerkleRoot,
        uint256 _phase1EndTimestamp,
        uint256 _phase2EndTimestamp,
        uint256 _phase3EndTimestamp
    ) ERC721("MultiUtilityNFT", "MUN") Ownable(_owner) EIP712("MultiUtilityNFT", "1") {
        if (address(_sablierLockup) == address(0)) revert ZeroAddress();
        if (address(_paymentToken) == address(0)) revert ZeroAddress();
        if (_phase1EndTimestamp <= block.timestamp) revert InvalidTimestamp();
        if (_phase2EndTimestamp <= _phase1EndTimestamp) revert InvalidTimestamp();
        if (_phase3EndTimestamp <= _phase2EndTimestamp) revert InvalidTimestamp();
        sablierLockup = _sablierLockup;
        paymentToken = _paymentToken;
        discountPrice = _discountPrice;
        fullPrice = _fullPrice;
        phase1MerkleRoot = _phase1MerkleRoot;
        phase2MerkleRoot = _phase2MerkleRoot;
        phase1EndTimestamp = _phase1EndTimestamp;
        phase2EndTimestamp = _phase2EndTimestamp;
        phase3EndTimestamp = _phase3EndTimestamp;
    }

    function mintPhase1(bytes32[] calldata proof) external nonReentrant {
        if (getCurrentPhase() != Phase.Phase1) revert InvalidPhase();
        if (phase1Claimed[msg.sender]) revert AlreadyClaimed();

        _validateProof(msg.sender, phase1MerkleRoot, proof);

        uint256 tokenId = _mintNFT(msg.sender);
        phase1Claimed[msg.sender] = true;

        emit Minted(msg.sender, tokenId, Phase.Phase1);
    }

    function mintPhase2(bytes calldata signature, bytes32[] calldata proof) external nonReentrant {
        if (getCurrentPhase() != Phase.Phase2) revert InvalidPhase();
        if (phase2Claimed[msg.sender]) revert AlreadyClaimed();

        _validateProof(msg.sender, phase2MerkleRoot, proof);
        _validateSignature(msg.sender, signature);

        paymentToken.safeTransferFrom(msg.sender, address(this), discountPrice);

        uint256 tokenId = _mintNFT(msg.sender);
        phase2Claimed[msg.sender] = true;

        emit Minted(msg.sender, tokenId, Phase.Phase2);
    }

    function mintPhase3() external nonReentrant {
        if (getCurrentPhase() != Phase.Phase3) revert InvalidPhase();

        paymentToken.safeTransferFrom(msg.sender, address(this), fullPrice);

        uint256 tokenId = _mintNFT(msg.sender);

        emit Minted(msg.sender, tokenId, Phase.Phase3);
    }

    function getCurrentPhase() public view returns (Phase) {
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp <= phase1EndTimestamp) {
            return Phase.Phase1;
        } else if (currentTimestamp <= phase2EndTimestamp) {
            return Phase.Phase2;
        } else if (currentTimestamp <= phase3EndTimestamp) {
            return Phase.Phase3;
        } else {
            return Phase.Finished;
        }
    }

    function _mintNFT(address account) internal returns (uint256) {
        uint256 tokenId = nextTokenId;
        nextTokenId++;
        _safeMint(account, tokenId);
        return tokenId;
    }

    function _validateProof(address account, bytes32 merkleRoot, bytes32[] calldata proof) internal pure {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) {
            revert InvalidProof();
        }
    }

    function _validateSignature(address account, bytes calldata signature) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("MultiUtilityNFT(uint256 chainid, address nft, address account)"),
                    block.chainid,
                    address(this),
                    account
                )
            )
        );
        address signer = ECDSA.recover(digest, signature);
        if (signer != owner()) {
            revert InvalidSignature();
        }
    }

    event Minted(address indexed account, uint256 tokenId, Phase phase);
}
