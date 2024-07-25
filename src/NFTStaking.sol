// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract NFTStaking is ERC721Holder, ERC1155Holder {
    struct NFTInfo {
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        bool isERC721;
    }

    mapping(address => NFTInfo[]) public stakedNFTs;

    event NFTsStaked(address indexed user, NFTInfo[] nfts);
    event NFTsUnstaked(address indexed user, uint256 amount);

    function stake(NFTInfo[] calldata _nfts) external {
        require(_nfts.length > 0, "Must stake at least one NFT");

        for (uint256 i = 0; i < _nfts.length; i++) {
            NFTInfo memory nft = _nfts[i];

            if (nft.isERC721) {
                require(nft.amount == 1, "ERC721 amount must be 1");
                IERC721(nft.nftContract).safeTransferFrom(msg.sender, address(this), nft.tokenId);
                stakedNFTs[msg.sender].push(nft);
            } else {
                require(nft.amount > 0, "ERC1155 amount must be greater than 0");
                IERC1155(nft.nftContract).safeTransferFrom(msg.sender, address(this), nft.tokenId, nft.amount, "");
                for (uint256 j = 0; j < nft.amount; j++) {
                    stakedNFTs[msg.sender].push(NFTInfo(nft.nftContract, nft.tokenId, 1, false));
                }
            }
        }

        emit NFTsStaked(msg.sender, _nfts);
    }

    function unstakeAll() external {
        uint256 stakedAmount = stakedNFTs[msg.sender].length;
        require(stakedAmount > 0, "No NFTs staked");

        for (uint256 i = 0; i < stakedAmount; i++) {
            NFTInfo memory nft = stakedNFTs[msg.sender][i];
            if (nft.isERC721) {
                IERC721(nft.nftContract).safeTransferFrom(address(this), msg.sender, nft.tokenId);
            } else {
                IERC1155(nft.nftContract).safeTransferFrom(address(this), msg.sender, nft.tokenId, nft.amount, "");
            }
        }

        delete stakedNFTs[msg.sender];
        emit NFTsUnstaked(msg.sender, stakedAmount);
    }

    function getStakedNFTs(address _user) external view returns (NFTInfo[] memory) {
        return stakedNFTs[_user];
    }
}