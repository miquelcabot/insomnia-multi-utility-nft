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
import {Broker, Lockup, LockupLinear} from "@sablier/lockup/src/types/DataTypes.sol";
import {ud60x18} from "prb-math/UD60x18.sol";

contract MultiUtilityNFT is ERC721, EIP712, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Phase {
        Phase1,
        Phase2,
        Phase3,
        Finished
    }

    // ----------- Error Codes -------------------------------------------------

    error ZeroAddress();
    error InvalidTimestamp();
    error InvalidPhase();
    error InvalidProof();
    error InvalidSignature();
    error AlreadyClaimed();

    // ----------- State Variables ---------------------------------------------

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

    // ----------- Constructor -------------------------------------------------

    /**
     * @notice Construct a new MultiUtilityNFT
     * @param _owner Address that will own the contract
     * @param _sablierLockup Sablier Lockup contract
     * @param _paymentToken ERC20 token used for payments
     * @param _discountPrice Price for Phase 2 minting
     * @param _fullPrice Price for Phase 3 minting
     * @param _phase1MerkleRoot Merkle root for Phase 1 claims
     * @param _phase2MerkleRoot Merkle root for Phase 2 claims
     * @param _phase1EndTimestamp Phase 1 end timestamp
     * @param _phase2EndTimestamp Phase 2 end timestamp
     * @param _phase3EndTimestamp Phase 3 end timestamp
     */
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

    // ----------- Mutable Functions -------------------------------------------

    /**
     * @notice Mint a new NFT in Phase 1 for free, verified by a Merkle proof
     * @param proof Merkle proof for the account that is minting the NFT
     */
    function mintPhase1(bytes32[] calldata proof) external nonReentrant {
        if (getCurrentPhase() != Phase.Phase1) revert InvalidPhase();
        if (phase1Claimed[msg.sender]) revert AlreadyClaimed();

        _validateProof(msg.sender, phase1MerkleRoot, proof);

        uint256 tokenId = _mintNFT(msg.sender);
        phase1Claimed[msg.sender] = true;

        emit Minted(msg.sender, tokenId, Phase.Phase1);
    }

    /**
     * @notice Mint a new NFT in Phase 2 for a discount, verified by a Merkle proof and a signature
     * @param signature Signature from the owner
     * @param proof Merkle proof for the account that is minting the NFT
     */
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

    /**
     * @notice Mint a new NFT in Phase 3 for the full price
     */
    function mintPhase3() external nonReentrant {
        if (getCurrentPhase() != Phase.Phase3) revert InvalidPhase();

        paymentToken.safeTransferFrom(msg.sender, address(this), fullPrice);

        uint256 tokenId = _mintNFT(msg.sender);

        emit Minted(msg.sender, tokenId, Phase.Phase3);
    }

    // ----------- Restricted Functions ----------------------------------------

    /**
     * @notice Lock the remaining minting fees on Sablier
     * @dev This function can only be called by the owner
     */
    function lockMintingFundsOnSablier() external onlyOwner {
        if (getCurrentPhase() != Phase.Finished) revert InvalidPhase();

        uint256 balance = paymentToken.balanceOf(address(this));
        Lockup.CreateWithDurations memory params = Lockup.CreateWithDurations({
            sender: owner(),
            recipient: owner(),
            totalAmount: uint128(balance),
            token: IERC20(address(paymentToken)),
            cancelable: false,
            transferable: true,
            shape: "",
            broker: Broker(address(0), ud60x18(0))
        });
        LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({start: 0, cliff: 0});
        LockupLinear.Durations memory durations = LockupLinear.Durations({cliff: 0, total: uint40(365 days)});
        paymentToken.safeIncreaseAllowance(address(sablierLockup), balance);
        sablierLockup.createWithDurationsLL(params, unlockAmounts, durations);
    }

    // ----------- View Functions ----------------------------------------------

    /**
     * @notice Get the current phase
     * @return The current phase
     */
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

    // ----------- Internal Functions ------------------------------------------

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

    // ----------- Events ------------------------------------------------------

    /**
     * Emitted when a new NFT is minted
     * @param account Address that minted the NFT
     * @param tokenId ID of the minted NFT
     * @param phase Phase in which the NFT was minted
     */
    event Minted(address indexed account, uint256 tokenId, Phase phase);
}
