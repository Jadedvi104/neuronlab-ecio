// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Helper.sol";

interface IECIONFT {
    function tokenInfo(uint256 _tokenId)
        external
        view
        returns (string memory, uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function burn(uint256 _tokenId) external;

    function safeMint(address _to, string memory partCode) external;
}

interface RANDOM_CONTRACT {
    function startRandom() external returns (uint256);
}

interface ISUCCSRATE {
    function getSuccessRate(
        uint16 starNum,
        uint16 cardNum,
        uint16 _number
    ) external view returns (uint16);
}

contract NeuronLab is Ownable {
    //Part Code Index
    uint256 constant PC_NFT_TYPE = 12;
    uint256 constant PC_KINGDOM = 11;
    uint256 constant PC_CAMP = 10;
    uint256 constant PC_GEAR = 9;
    uint256 constant PC_DRONE = 8;
    uint256 constant PC_SUITE = 7;
    uint256 constant PC_BOT = 6;
    uint256 constant PC_GENOME = 5;
    uint256 constant PC_WEAPON = 4;
    uint256 constant PC_STAR = 3;
    uint256 constant PC_EQUIPMENT = 2;
    uint256 constant PC_RESERVED1 = 1;
    uint256 constant PC_RESERVED2 = 0;

    //Genom Rarity Code
    uint32 constant GENOME_COMMON = 0;
    uint32 constant GENOME_RARE = 1;
    uint32 constant GENOME_EPIC = 2;
    uint32 constant GENOME_LEGENDARY = 3;
    uint32 constant GENOME_LIMITED = 4;

    //Stars tier string
    string constant ZERO_STAR = "00";
    string constant ONE_STAR = "01";
    string constant TWO_STAR = "02";
    string constant THREE_STAR = "03";
    string constant FOUR_STAR = "04";
    string constant FIVE_STAR = "05";

    //Star
    uint16 private constant ZEO_STAR_UINT = 0;
    uint16 private constant ONE_STAR_UINT = 1;
    uint16 private constant TWO_STAR_UINT = 2;
    uint16 private constant THREE_STAR_UINT = 3;
    uint16 private constant FOUR_STAR_UINT = 4;

    //FAILED OR SUCCESS
    uint16 private constant SUCCEEDED = 0;
    uint16 private constant FAILED = 1;

    //rate being charged to upgrade stars
    uint256 public upgradeRate;

    //Mapping to check Genom Rarity
    mapping(string => uint32) public genomRarity;

    IECIONFT public NFTCore;
    IERC20 public ECIO_TOKEN;
    ISUCCSRATE public SUCCESSRATE;
    RANDOM_CONTRACT public RANDOM_WORKER;

    //Setup ECIO Token Address
    function setupEcioToken(address ecioTokenAddr) public onlyOwner {
        ECIO_TOKEN = IERC20(ecioTokenAddr);
    }

    //Setup NFTcore address
    function setupNFTCore(IECIONFT nftCore) public onlyOwner {
        NFTCore = nftCore;
    }

    //Setup NFTcore address
    function setupRandomCa(ISUCCSRATE randomCa) public onlyOwner {
        SUCCESSRATE = randomCa;
    }

    //Setup RandomWorker address
    function setupRandomWorker(RANDOM_CONTRACT randomWorkerContract)
        public
        onlyOwner
    {
        RANDOM_WORKER = randomWorkerContract;
    }

    //Setup NFTcore address
    function setupRate(uint256 newRate) public onlyOwner {
        upgradeRate = newRate;
    }

    //Compare 2 strings
    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    //Get user Partcode and then split the code to check Genomic numbers
    function splitGenom(string memory partCode)
        public
        pure
        returns (string memory)
    {
        string[] memory splittedPartCodes = splitPartCode(partCode);
        string memory genType = splittedPartCodes[PC_GENOME];

        return (genType);
    }

    //Get user Genomic Partcode and then split the code to check Genomic Rarity
    function checkUserGenomRarity(string memory genomPart)
        public
        view
        returns (uint32)
    {
        if (genomRarity[genomPart] == GENOME_COMMON) {
            return GENOME_COMMON;
        } else if (genomRarity[genomPart] == GENOME_RARE) {
            return GENOME_RARE;
        } else if (genomRarity[genomPart] == GENOME_EPIC) {
            return GENOME_EPIC;
        } else if (genomRarity[genomPart] == GENOME_LEGENDARY) {
            return GENOME_LEGENDARY;
        } else if (genomRarity[genomPart] == GENOME_LIMITED) {
            return GENOME_LIMITED;
        } else {
            return 999; // need to change this
        }
    }

    //Get user Partcode and then split the code to check stars numbers
    function splitPartcodeStar(string memory partCode)
        public
        pure
        returns (string memory)
    {
        string[] memory splittedPartCodes = splitPartCode(partCode);
        string memory starCode = splittedPartCodes[PC_STAR];

        return starCode;
    }

    //Convert from string to uint16
    function convertStarToUint(string memory starPart)
        public
        pure
        returns (uint16 stars)
    {
        if (compareStrings(starPart, ZERO_STAR) == true) {
            return ZEO_STAR_UINT;
        } else if (compareStrings(starPart, ONE_STAR) == true) {
            return ONE_STAR_UINT;
        } else if (compareStrings(starPart, TWO_STAR) == true) {
            return TWO_STAR_UINT;
        } else if (compareStrings(starPart, THREE_STAR) == true) {
            return THREE_STAR_UINT;
        } else if (compareStrings(starPart, FOUR_STAR) == true) {
            return FOUR_STAR_UINT;
        }

        return ZEO_STAR_UINT; // need fix
    }

    //Split partcode for each part
    function splitPartCode(string memory partCode)
        public
        pure
        returns (string[] memory)
    {
        string[] memory result = new string[](bytes(partCode).length / 2);
        for (uint256 index = 0; index < bytes(partCode).length / 2; index++) {
            result[index] = string(
                abi.encodePacked(
                    bytes(partCode)[index * 2],
                    bytes(partCode)[(index * 2) + 1]
                )
            );
        }
        return result;
    }

    //Combine partcode
    function createPartCode(
        string memory equipmentCode,
        string memory starCode,
        string memory weapCode,
        string memory humanGENCode,
        string memory battleBotCode,
        string memory battleSuiteCode,
        string memory battleDROCode,
        string memory battleGearCode,
        string memory trainingCode,
        string memory kingdomCode,
        string memory nftTypeCode
    ) public pure returns (string memory) {
        string memory code = concateCode("", "00");
        code = concateCode(code, "00");
        code = concateCode(code, equipmentCode);
        code = concateCode(code, starCode);
        code = concateCode(code, weapCode);
        code = concateCode(code, humanGENCode);
        code = concateCode(code, battleBotCode);
        code = concateCode(code, battleSuiteCode);
        code = concateCode(code, battleDROCode);
        code = concateCode(code, battleGearCode);
        code = concateCode(code, trainingCode); //Reserved
        code = concateCode(code, kingdomCode); //Reserved
        code = concateCode(code, nftTypeCode); //Reserved
        return code;
    }

    function concateCode(string memory concatedCode, string memory newCode)
        public
        pure
        returns (string memory)
    {
        concatedCode = string(abi.encodePacked(concatedCode, newCode));

        return concatedCode;
    }

    function getNumberAndMod(
        uint256 _ranNum,
        uint16 digit,
        uint16 mod
    ) public view virtual returns (uint16) {
        if (digit == 1) {
            return uint16((_ranNum % 10000) % mod);
        } else if (digit == 2) {
            return uint16(((_ranNum % 100000000) / 10000) % mod);
        } else if (digit == 3) {
            return uint16(((_ranNum % 1000000000000) / 100000000) % mod);
        }

        return 0;
    }

    //Get Card id and then burn them and mint a new one
    function gatherMaterials(uint256[] memory tokenIds, uint256 mainCardTokenId)
        external
    {
        require(
            ECIO_TOKEN.balanceOf(msg.sender) >= upgradeRate,
            "Token: your token is not enough"
        );

        string memory mainCardPart;
        (mainCardPart, ) = NFTCore.tokenInfo(mainCardTokenId);
        string memory mainCardGenom = splitGenom(mainCardPart);
        uint32 mainCardRarity = checkUserGenomRarity(mainCardGenom);

        //get main part code star
        string memory mainCardStar = splitPartcodeStar(mainCardPart);
        uint16 starConverted = convertStarToUint(mainCardStar);

        uint256 _randomNumber = RANDOM_CONTRACT(RANDOM_WORKER).startRandom(); // NEEDCHECK
        uint16 starId = getNumberAndMod(_randomNumber, 3, 1000); // NEEDCHECK

        // get success rate
        uint16 randomResult = SUCCESSRATE.getSuccessRate(
            starConverted,
            uint16(tokenIds.length),
            starId
        ); // NEEDCHECK

        if (randomResult == SUCCEEDED) {
            burnAndCheckToken(mainCardRarity, tokenIds);
            upgradeSW(mainCardStar, mainCardPart);
        } else if (randomResult == FAILED) {
            burnAndCheckToken(mainCardRarity, tokenIds);
        }
    }


    function burnAndCheckToken(uint32 mainCardRarity, uint256[] memory tokenIds)
        internal
    {
        if (mainCardRarity == GENOME_COMMON || mainCardRarity == GENOME_RARE) {
            for (uint32 i = 0; i < tokenIds.length; i++) {
                string memory tokenIdPart;
                (tokenIdPart, ) = NFTCore.tokenInfo(tokenIds[i]);
                string memory tokenIdsGenom = splitGenom(tokenIdPart);
                uint32 tokenIdsRarity = checkUserGenomRarity(tokenIdsGenom);

                require(
                    NFTCore.ownerOf(tokenIds[i]) == msg.sender,
                    "Ownership: you are not the owner"
                );

                require(
                    tokenIdsRarity == GENOME_COMMON,
                    "Rarity: your meterial must be common"
                );

                NFTCore.burn(tokenIds[i]);
            }
        } else if (
            mainCardRarity == GENOME_LIMITED || mainCardRarity == GENOME_EPIC
        ) {
            for (uint32 i = 0; i < tokenIds.length; i++) {
                string memory tokenIdPart;
                (tokenIdPart, ) = NFTCore.tokenInfo(tokenIds[i]);
                string memory tokenIdsGenom = splitGenom(tokenIdPart);
                uint32 tokenIdsRarity = checkUserGenomRarity(tokenIdsGenom);

                require(
                    NFTCore.ownerOf(tokenIds[i]) == msg.sender,
                    "Ownership: you are not the owner"
                );

                require(
                    tokenIdsRarity == GENOME_RARE,
                    "Rarity: your meterial must be common"
                );

                NFTCore.burn(tokenIds[i]);
            }
        } else if (mainCardRarity == GENOME_LEGENDARY) {
            for (uint32 i = 0; i < tokenIds.length; i++) {
                string memory tokenIdPart;
                (tokenIdPart, ) = NFTCore.tokenInfo(tokenIds[i]);
                string memory tokenIdsGenom = splitGenom(tokenIdPart);
                uint32 tokenIdsRarity = checkUserGenomRarity(tokenIdsGenom);

                require(
                    NFTCore.ownerOf(tokenIds[i]) == msg.sender,
                    "Ownership: you are not the owner"
                );

                require(
                    tokenIdsRarity == GENOME_EPIC,
                    "Rarity: your meterial must be common"
                );

                NFTCore.burn(tokenIds[i]);
            }
        }
    }

    function upgradeSW(string memory mainCardStar, string memory mainCardPart)
        internal
    {
        // Upgrade from 0 Star to 1 star
        if (compareStrings(mainCardStar, ZERO_STAR) == true) {
            // split part code
            string[] memory splittedPartCode = splitPartCode(mainCardPart);
            // change part code
            splittedPartCode[PC_STAR] = ONE_STAR;
            // update partcode
            string memory partCode = createPartCode(
                splittedPartCode[PC_EQUIPMENT], //equipmentTypeId
                splittedPartCode[PC_STAR], //combatStarCode
                splittedPartCode[PC_WEAPON], //WEAPCode
                splittedPartCode[PC_GENOME], //humanGENCode
                splittedPartCode[PC_BOT], //battleBotCode
                splittedPartCode[PC_SUITE], //battleSuiteCode
                splittedPartCode[PC_DRONE], //battleDROCode
                splittedPartCode[PC_GEAR], //battleGearCode
                splittedPartCode[PC_CAMP], //trainingCode
                splittedPartCode[PC_KINGDOM], //kingdomCode
                splittedPartCode[PC_NFT_TYPE] // nft Type
            );

            NFTCore.safeMint(msg.sender, partCode);
        } else if (compareStrings(mainCardStar, ONE_STAR) == true) {
            // split part code
            string[] memory splittedPartCode = splitPartCode(mainCardPart);
            // change part code
            splittedPartCode[PC_STAR] = TWO_STAR;
            // update partcode
            string memory partCode = createPartCode(
                splittedPartCode[PC_EQUIPMENT], //equipmentTypeId
                splittedPartCode[PC_STAR], //combatStarCode
                splittedPartCode[PC_WEAPON], //WEAPCode
                splittedPartCode[PC_GENOME], //humanGENCode
                splittedPartCode[PC_BOT], //battleBotCode
                splittedPartCode[PC_SUITE], //battleSuiteCode
                splittedPartCode[PC_DRONE], //battleDROCode
                splittedPartCode[PC_GEAR], //battleGearCode
                splittedPartCode[PC_CAMP], //trainingCode
                splittedPartCode[PC_KINGDOM], //kingdomCode
                splittedPartCode[PC_NFT_TYPE] // nft Type
            );

            NFTCore.safeMint(msg.sender, partCode);
        } else if (compareStrings(mainCardStar, TWO_STAR) == true) {
            // split part code
            string[] memory splittedPartCode = splitPartCode(mainCardPart);
            // change part code
            splittedPartCode[PC_STAR] = THREE_STAR;
            // update partcode
            string memory partCode = createPartCode(
                splittedPartCode[PC_EQUIPMENT], //equipmentTypeId
                splittedPartCode[PC_STAR], //combatStarCode
                splittedPartCode[PC_WEAPON], //WEAPCode
                splittedPartCode[PC_GENOME], //humanGENCode
                splittedPartCode[PC_BOT], //battleBotCode
                splittedPartCode[PC_SUITE], //battleSuiteCode
                splittedPartCode[PC_DRONE], //battleDROCode
                splittedPartCode[PC_GEAR], //battleGearCode
                splittedPartCode[PC_CAMP], //trainingCode
                splittedPartCode[PC_KINGDOM], //kingdomCode
                splittedPartCode[PC_NFT_TYPE] // nft Type
            );

            NFTCore.safeMint(msg.sender, partCode);
        } else if (compareStrings(mainCardStar, THREE_STAR) == true) {
            // split part code
            string[] memory splittedPartCode = splitPartCode(mainCardPart);
            // change part code
            splittedPartCode[PC_STAR] = FOUR_STAR;
            // update partcode
            string memory partCode = createPartCode(
                splittedPartCode[PC_EQUIPMENT], //equipmentTypeId
                splittedPartCode[PC_STAR], //combatStarCode
                splittedPartCode[PC_WEAPON], //WEAPCode
                splittedPartCode[PC_GENOME], //humanGENCode
                splittedPartCode[PC_BOT], //battleBotCode
                splittedPartCode[PC_SUITE], //battleSuiteCode
                splittedPartCode[PC_DRONE], //battleDROCode
                splittedPartCode[PC_GEAR], //battleGearCode
                splittedPartCode[PC_CAMP], //trainingCode
                splittedPartCode[PC_KINGDOM], //kingdomCode
                splittedPartCode[PC_NFT_TYPE] // nft Type
            );

            NFTCore.safeMint(msg.sender, partCode);
        } else if (compareStrings(mainCardStar, FOUR_STAR) == true) {
            // split part code
            string[] memory splittedPartCode = splitPartCode(mainCardPart);
            // change part code
            splittedPartCode[PC_STAR] = FIVE_STAR;
            // update partcode
            string memory partCode = createPartCode(
                splittedPartCode[PC_EQUIPMENT], //equipmentTypeId
                splittedPartCode[PC_STAR], //combatStarCode
                splittedPartCode[PC_WEAPON], //WEAPCode
                splittedPartCode[PC_GENOME], //humanGENCode
                splittedPartCode[PC_BOT], //battleBotCode
                splittedPartCode[PC_SUITE], //battleSuiteCode
                splittedPartCode[PC_DRONE], //battleDROCode
                splittedPartCode[PC_GEAR], //battleGearCode
                splittedPartCode[PC_CAMP], //trainingCode
                splittedPartCode[PC_KINGDOM], //kingdomCode
                splittedPartCode[PC_NFT_TYPE] // nft Type
            );

            NFTCore.safeMint(msg.sender, partCode);
        }
    }

    //*************************** transfer fee ***************************//

    function transferFee(address payable _to, uint256 _amount)
        public
        onlyOwner
    {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function transferReward(
        address _contractAddress,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        IERC20 _token = IERC20(_contractAddress);
        _token.transfer(_to, _amount);
    }
}
