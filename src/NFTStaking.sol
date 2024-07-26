// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract NFTStaking is ERC721Holder, ERC1155Holder {
    struct NftInfo {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
        bool isERC721;
    }

    struct NftInput {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
    }

    mapping(address => uint256) public totalStakedCount;
    mapping(address => uint256) public currentStakedCount;
    mapping(address => mapping(uint256 => NftInfo)) public stakedNfts;

    event NftsStaked(address indexed user, NftInput[] nfts);
    event NftsUnstaked(address indexed user, uint256 amount);

    function stake(NftInput[] calldata _nfts) external {
        require(_nfts.length > 0, "Must stake at least one NFT");

        for (uint256 i = 0; i < _nfts.length; i++) {
            NftInput memory nftInput = _nfts[i];
            bool isERC721 = IERC165(nftInput.contractAddress).supportsInterface(type(IERC721).interfaceId);

            if (isERC721) {
                require(nftInput.amount == 1, "ERC721 amount must be 1");
                IERC721(nftInput.contractAddress).safeTransferFrom(msg.sender, address(this), nftInput.tokenId);
            } else {
                require(nftInput.amount > 0, "ERC1155 amount must be greater than 0");
                IERC1155(nftInput.contractAddress).safeTransferFrom(msg.sender, address(this), nftInput.tokenId, nftInput.amount, "");
            }

            NftInfo memory nftInfo = NftInfo(nftInput.contractAddress, nftInput.tokenId, nftInput.amount, isERC721);

            totalStakedCount[msg.sender]++;
            currentStakedCount[msg.sender]++;
            stakedNfts[msg.sender][totalStakedCount[msg.sender]] = nftInfo;
        }

        emit NftsStaked(msg.sender, _nfts);
    }

    function unstakeAll() external {
        uint256 stakedAmount = currentStakedCount[msg.sender]++;
        require(stakedAmount > 0, "No NFTs staked");

        for (uint256 i = 0; i < totalStakedCount[msg.sender]; i++) {
            NftInfo memory nftInfo = stakedNfts[msg.sender][i + 1];
            if (nftInfo.amount == 0) continue;
            if (nftInfo.isERC721) {
                IERC721(nftInfo.contractAddress).safeTransferFrom(address(this), msg.sender, nftInfo.tokenId);
            } else {
                IERC1155(nftInfo.contractAddress).safeTransferFrom(address(this), msg.sender, nftInfo.tokenId, nftInfo.amount, "");
            }
            delete stakedNfts[msg.sender][i + 1];
        }

        emit NftsUnstaked(msg.sender, currentStakedCount[msg.sender]);
        currentStakedCount[msg.sender] = 0;
    }

    function getStakedNFTs(address _user) external view returns (NftInfo[] memory) {
        uint256 stakedAmount = currentStakedCount[_user];
        NftInfo[] memory nfts = new NftInfo[](stakedAmount);
        
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalStakedCount[_user]; i++) {
            NftInfo memory nftInfo = stakedNfts[_user][i + 1];
            if (nftInfo.amount == 0) continue;
            nfts[currentIndex] = nftInfo;
            currentIndex++;
        }

        return nfts;
    }
}