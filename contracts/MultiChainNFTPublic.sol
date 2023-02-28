// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// FTSO system
import {IFtso} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFtso.sol";
import {IPriceSubmitter} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IPriceSubmitter.sol";
import {IFtsoRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFtsoRegistry.sol";

// State connector
import {IAttestationClient} from "@flarenetwork/flare-periphery-contracts/coston2/stateConnector/interface/IAttestationClient.sol";

struct ReservationInfo {
    bytes32 _paymentReference;
    string _targetAddress;
    uint256 _payableAmount;
}

contract FlareMultiChainNft is ERC721 {
    error UnsupportedChain(string wrongChain);
    error InsufficientReservation();
    error InvalidReservation();
    error InvalidPaymentAddresss();
    error InsufficientPaymentAmount(int256 needed, int256 paid);
    error WrongPaymentReference();
    error PaymentTooOld();
    error InvalidStateConectorProof();
    error FailedPayment();
    error RanOutOfReservations();

    struct Reservation {
        string chain;
        uint256 tokenId;
        uint256 payableAmount;
        uint256 reservationTime;
        bytes32 paymentReference;
        string targetChainPaymentAddress;
        bool executed;
    }

    // IPFS can be a bit slow (on explorer), so we cheat and gateway it through something else
    struct URIInfo {
        string ipfsURI;
        string gatewayedURI;
    }

    struct ChainInfo {
        string symbol;
        uint32 chainId;
        string targetAddress;
        uint256 maxWaitingTimeSeconds;
        uint256 decimals;
        URIInfo uriInfo;
    }

    event ReservationCreated(
        address indexed account,
        uint256 indexed tokenId,
        string indexed chain,
        bytes32 paymentReference,
        string targetAddress,
        uint256 _payableAmount
    );

    event ExpiredReservationClosed(
        address indexed account,
        string indexed chain,
        address indexed oldAddress,
        uint256 tokenId
    );

    bool allowReservationOverride = true;

    uint256 public immutable dollarPriceWeiCost;
    uint256 weiDollarPriceDecimals = 2;

    mapping(uint256 => string) public tokenChain;

    mapping(string => ChainInfo) public chainInfo;

    mapping(address => Reservation) public reservations;

    mapping(string => string) public ftosRegistryChainMapper;

    uint256 public reservationCostWei = 10;

    uint256 public currentTokenId = 0;

    bytes32 public constant RESERVATION_SALT = keccak256("RESERVATION_SALT");

    string dogeRawMetadataURI =
        "QmQnzU8RQ45N8F78AtRoowZ6TMck5zLPrhD5teGa4RhQBJ";
    string dogeGatewayMetadataURI =
        "QmV6mL9F6KFJ8rYX3ARmUm8xEo9GQUhM5Udd6fkKeAWrLu";

    string xrpRawMetadataURI = "QmSBLdMvg22Rf1p1uUxGPPXxBvodJ7UhwT4BX2V2LfezVf";
    string xrpGatewayMetadataURI =
        "QmVFyMRLgFoCTxFZLZb793Ji79qzrPhnFEBro5o7VYmxmm";

    address public immutable owner;

    bool public useGatewayedUrl = true;

    uint256 maxWaitingTime = 6 * 60 * 60; // 6 hours

    uint256 saltLimit = 10**3;

    string[5] public chains = ["DOGE", "XRP"];
    mapping(string => uint256) availableTokens;

    function initialize_ftso_names() private {
        string memory prefix = "";
        if (block.chainid == 114 || block.chainid == 16) {
            // Coston2 or Coston
            prefix = "test";
        } else if (block.chainid == 14 || block.chainid == 19) {} else {
            // Flare or Songbird
            revert("Unsupported chain");
        }

        for (uint256 i = 0; i < chains.length; ++i) {
            ftosRegistryChainMapper[chains[i]] = string(
                abi.encodePacked(prefix, chains[i])
            );
        }
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _dollarPriceWeiCost
    ) ERC721(name_, symbol_) {
        owner = msg.sender;
        dollarPriceWeiCost = _dollarPriceWeiCost;

        initialize_ftso_names();

        chainInfo["DOGE"] = ChainInfo(
            "DOGE",
            2,
            "DEUNM99Stpjzhuz8ubTaFn53fSxXVrExX3",
            maxWaitingTime,
            8,
            URIInfo(dogeRawMetadataURI, dogeGatewayMetadataURI)
        );

        chainInfo["XRP"] = ChainInfo(
            "XRP",
            3,
            "rHKZ84GyNzUBc6mjvRCKBrhw3kZigJVveH",
            maxWaitingTime,
            6,
            URIInfo(xrpRawMetadataURI, xrpGatewayMetadataURI)
        );

        availableTokens["DOGE"] = 100;
        availableTokens["XRP"] = 100;

        // _executeMint(msg.sender, "DOGE", 1);
        // ++currentTokenId;
        // --availableTokens["DOGE"];
    }

    function getPriceSubmitter() public view virtual returns (IPriceSubmitter) {
        return IPriceSubmitter(0x1000000000000000000000000000000000000003);
    }

    function getAttestationClient()
        public
        view
        virtual
        returns (IAttestationClient)
    {
        return IAttestationClient(0x8858eeB3DfffA017D4BCE9801D340D36Cf895CCf); // Coston 2
        // return IAttestationClient(0xa8323646aFDC59270ac00F8B27401EE371535CF7); // Songbird
    }

    function getPriceInTargetCurrency(string memory _symbol)
        public
        view
        returns (uint256)
    {
        IFtsoRegistry ftsoRegistry = IFtsoRegistry(
            address(getPriceSubmitter().getFtsoRegistry())
        );
        uint256 foreignTokenDecimalsToUsd = 5;

        ChainInfo memory info = chainInfo[_symbol];

        (uint256 foreignTokenToUsdDecimals, ) = ftsoRegistry.getCurrentPrice(
            ftosRegistryChainMapper[_symbol]
        );
        uint256 price = (dollarPriceWeiCost *
            (10**foreignTokenDecimalsToUsd) *
            (10**info.decimals)) /
            (foreignTokenToUsdDecimals * (10**weiDollarPriceDecimals));

        // We use last few digits of payment amount to get the reference
        uint256 rem = price % saltLimit;
        price = price + saltLimit - rem + currentTokenId + 1;
        return price;
    }

    function calculateReservationReference(
        string memory _chainSymbol,
        uint256 _tokenId,
        address _sender
    ) public view returns (bytes32) {
        return keccak256(abi.encode("FLARE_TOKEN"));
        // return keccak256(abi.encode(RESERVATION_SALT, _chainSymbol, _tokenId, address(_sender), address(this)));
    }

    // function reserveFor(
    //     string memory _chainSymbol,
    //     address target,
    //     address oldReservationHolder,
    //     bool _continue
    // ) public returns (ReservationInfo memory _reservation) {
    //     Reservation storage existing = reservations[oldReservationHolder];
    //     if (existing.reservationTime + maxWaitingTime < block.timestamp) {
    //         if (existing.reservationTime != 0 && existing.executed == false) {
    //             emit ExpiredReservationClosed(
    //                 msg.sender,
    //                 existing.chain,
    //                 oldReservationHolder,
    //                 existing.tokenId
    //             );
    //             ++availableTokens[existing.chain];
    //             delete reservations[oldReservationHolder];
    //         }
    //         if (_continue) {
    //             return reserveFor(_chainSymbol, target);
    //         }
    //     } else {
    //         revert("Did not expire");
    //     }
    // }

    function reserveFor(string memory _chainSymbol, address target)
        public
        returns (ReservationInfo memory)
    {
        ChainInfo memory info = chainInfo[_chainSymbol];
        if (bytes(info.symbol).length == 0) {
            revert UnsupportedChain(_chainSymbol);
        }
        if (!allowReservationOverride) {
            Reservation memory reservation = reservations[target];
            if (reservation.reservationTime != 0) {
                if (
                    keccak256(abi.encode(reservation.chain)) !=
                    keccak256(abi.encode(_chainSymbol))
                ) {
                    revert("Different chain");
                }
                return
                    ReservationInfo(
                        reservation.paymentReference,
                        reservation.targetChainPaymentAddress,
                        reservation.payableAmount
                    );
            }
        }

        // if(msg.value < reservationCostWei) {
        //     revert InsufficientReservation();
        // }

        uint256 _payableAmount = getPriceInTargetCurrency(info.symbol);
        ++currentTokenId;

        if (availableTokens[_chainSymbol] <= 0) {
            revert RanOutOfReservations();
        }
        --availableTokens[_chainSymbol];
        bytes32 paymentReference = calculateReservationReference(
            _chainSymbol,
            currentTokenId,
            msg.sender
        );

        reservations[target] = Reservation(
            _chainSymbol,
            currentTokenId,
            _payableAmount,
            block.timestamp,
            paymentReference,
            info.targetAddress,
            false
        );

        emit ReservationCreated(
            target,
            currentTokenId,
            _chainSymbol,
            paymentReference,
            info.targetAddress,
            _payableAmount
        );

        return
            ReservationInfo(
                paymentReference,
                info.targetAddress,
                _payableAmount
            );
    }

    function reserve(string memory _chainSymbol)
        public
        returns (ReservationInfo memory)
    {
        return reserveFor(_chainSymbol, msg.sender);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://ipfs/";
    }

    function getTokenUriInfo(uint256 tokenId)
        public
        view
        returns (URIInfo memory)
    {
        _requireMinted(tokenId);
        string storage targetChain = tokenChain[tokenId];
        URIInfo memory data = chainInfo[targetChain].uriInfo;
        return data;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (useGatewayedUrl) {
            return getGatewayTokenURI(tokenId);
        } else {
            URIInfo memory info = getTokenUriInfo(tokenId);
            return string(abi.encodePacked(_baseURI(), info.ipfsURI));
        }
    }

    function getGatewayTokenURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        URIInfo memory info = getTokenUriInfo(tokenId);
        return
            string(
                abi.encodePacked(
                    "https://cloudflare-ipfs.com/ipfs/",
                    info.gatewayedURI
                )
            );
    }

    function setUseGatewayed(bool _useGatewayed) public {
        require(msg.sender == owner, "");
        useGatewayedUrl = _useGatewayed;
    }

    function checkProofValidity(
        ChainInfo memory _chainInfo,
        IAttestationClient.Payment memory _payment
    ) public view {
        // Verify that the payment is valid
        IAttestationClient attestationClient = getAttestationClient();
        if (!attestationClient.verifyPayment(_chainInfo.chainId, _payment)) {
            revert InvalidStateConectorProof();
        }
    }

    function calculateAddressHash(string memory addr)
        public
        pure
        returns (bytes32)
    {
        return keccak256(bytes(addr));
    }

    function checkPaymentValidity(
        ChainInfo memory _chainInfo,
        Reservation memory _reservation,
        IAttestationClient.Payment memory _payment
    ) public view returns (bool) {
        // Verify that _payment is the same as requested in reservation

        if (_payment.status != 0) {
            revert FailedPayment();
        }

        // Verify that the payment is to correct address
        if (
            calculateAddressHash(_reservation.targetChainPaymentAddress) !=
            _payment.receivingAddressHash
        ) {
            revert InvalidPaymentAddresss();
        }

        // Verify that the payment has correct amount
        if (
            int256(_reservation.payableAmount) > _payment.receivedAmount &&
            int256(_reservation.payableAmount) < 30 // Account for volatility of the price
        ) {
            revert InsufficientPaymentAmount(
                int256(_reservation.payableAmount),
                _payment.receivedAmount
            );
        }
        // Verify that the payment has correct reference
        // if (_reservation.paymentReference != _payment.paymentReference) {
        //     revert WrongPaymentReference();
        // }

        // Verify that the payment has correct salt
        if (_reservation.payableAmount % saltLimit != _reservation.tokenId) {
            revert WrongPaymentReference();
        }

        // Verify that the payment is not too old
        // We ship this and allow users to throw out reservations if needed
        // if (
        //     block.timestamp - _reservation.reservationTime >
        //     _chainInfo.maxWaitingTimeSeconds
        // ) {
        //     revert PaymentTooOld();
        // }

        return true;
    }

    function checkFullPaymentValidity(
        IAttestationClient.Payment memory _payment
    ) public view returns (bool) {
        Reservation memory reservation = reservations[msg.sender];
        if (reservation.reservationTime == 0) {
            revert InvalidReservation();
        }

        ChainInfo memory info = chainInfo[reservation.chain];

        checkPaymentValidity(info, reservation, _payment);

        // Verify that the payment is valid
        checkProofValidity(info, _payment);

        return true;
    }

    function _executeMint(
        address _target,
        string memory chain,
        uint256 tokenId
    ) private {
        tokenChain[tokenId] = chain;
        _safeMint(_target, tokenId);
    }

    function mintNft(IAttestationClient.Payment memory _payment)
        public
        returns (bool)
    {
        checkFullPaymentValidity(_payment);

        Reservation memory reservation = reservations[msg.sender];

        delete reservations[msg.sender];
        _executeMint(msg.sender, reservation.chain, reservation.tokenId);
        return true;
    }

    function setChainInfo(string memory chainSymbol, ChainInfo memory info)
        public
    {
        require(msg.sender == owner, "Only owner can set chain info");
        require(
            bytes(chainInfo[chainSymbol].symbol).length > 0,
            "Chain must already exist"
        );
        chainInfo[chainSymbol] = info;
    }
}
