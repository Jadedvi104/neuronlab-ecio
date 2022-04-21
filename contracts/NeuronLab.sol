// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IECIONFT {
    function tokenInfo(uint256 _tokenId)
        external
        view
        returns (string memory, uint256);
}

contract NeuronLab is Ownable {
    // Part Code Index
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

    string constant ZERO_STAR = "00";
    string constant ONE_STAR = "01";
    string constant TWO_STAR = "02";
    string constant THREE_STAR = "03";
    string constant FOUR_STAR = "04";
    string constant FIVE_STAR = "05";

    IECIONFT public NFTCore;
    IERC20 public ECIO_TOKEN;

    function checkUserRarity(string memory partCode)
        public
        pure
        returns (string memory)
    {
        string[] memory splittedPartCodes = splitPartCode(partCode);
        string memory nftType = splittedPartCodes[PC_NFT_TYPE];

        return (nftType);
    }

    function checkUserStars(string memory partCode)
        public
        pure
        returns (string memory)
    {
        string[] memory splittedPartCodes = splitPartCode(partCode);
        string memory starCode = splittedPartCodes[PC_STAR];

        return (starCode);
    }

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

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function compareStar(uint256 tokenIds) public view returns (string memory) {
        string memory partCode;
        uint256 id;
        (partCode, id) = NFTCore.tokenInfo(tokenIds);

        if (compareStrings(ONE_STAR, checkUserStars(partCode)) == true) {
            return ONE_STAR;
        }
        
        if (compareStrings(TWO_STAR, checkUserStars(partCode)) == true) {
            return TWO_STAR;
        }

        if (compareStrings(THREE_STAR, checkUserStars(partCode)) == true) {
            return THREE_STAR;
        }
        if (compareStrings(FOUR_STAR, checkUserStars(partCode)) == true) {
            return FOUR_STAR;
        }
        if (compareStrings(FIVE_STAR, checkUserStars(partCode)) == true) {
            return FIVE_STAR;
        }

        return ZERO_STAR;
    }

    function calculatePercent() public view returns (uint256) {}

    function addSwToForge() public {}

    function gatherMaterials(uint256[] memory tokenIds)
        internal
        view
        returns (uint256[] memory)
    {}

    function upgradeTier(uint256 tokenId) external {}

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
