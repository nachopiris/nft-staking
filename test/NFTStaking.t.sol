// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTStaking.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract NFTStakingTest is ERC721Holder, ERC1155Holder, Test {
    NFTStaking nftStaking;
    MockERC721 erc721;
    MockERC1155 erc1155;

    function setUp() public {
        nftStaking = new NFTStaking();
        erc721 = new MockERC721();
        erc1155 = new MockERC1155();
    }

    function testStakeERC721() public {
        erc721.mint(address(this), 1);
        erc721.approve(address(nftStaking), 1);

        NFTStaking.NFTInfo[] memory nfts = new NFTStaking.NFTInfo[](1);
        nfts[0] = NFTStaking.NFTInfo(address(erc721), 1, 1, true);

        nftStaking.stake(nfts);

        NFTStaking.NFTInfo[] memory stakedNFTs = nftStaking.getStakedNFTs(address(this));
        assertEq(stakedNFTs.length, 1);
        assertEq(stakedNFTs[0].nftContract, address(erc721));
        assertEq(stakedNFTs[0].tokenId, 1);
        assertEq(stakedNFTs[0].amount, 1);
        assertTrue(stakedNFTs[0].isERC721);
    }

    function testStakeERC1155() public {
        erc1155.mint(address(this), 1, 5);
        erc1155.setApprovalForAll(address(nftStaking), true);

        NFTStaking.NFTInfo[] memory nfts = new NFTStaking.NFTInfo[](1);
        nfts[0] = NFTStaking.NFTInfo(address(erc1155), 1, 5, false);

        nftStaking.stake(nfts);

        NFTStaking.NFTInfo[] memory stakedNFTs = nftStaking.getStakedNFTs(address(this));
        assertEq(stakedNFTs.length, 5);
        for (uint256 i = 0; i < 5; i++) {
            assertEq(stakedNFTs[i].nftContract, address(erc1155));
            assertEq(stakedNFTs[i].tokenId, 1);
            assertEq(stakedNFTs[i].amount, 1);
            assertFalse(stakedNFTs[i].isERC721);
        }
    }

    function testUnstakeAll() public {
        erc721.mint(address(this), 1);
        erc721.approve(address(nftStaking), 1);

        NFTStaking.NFTInfo[] memory nfts = new NFTStaking.NFTInfo[](1);
        nfts[0] = NFTStaking.NFTInfo(address(erc721), 1, 1, true);

        nftStaking.stake(nfts);
        nftStaking.unstakeAll();

        NFTStaking.NFTInfo[] memory stakedNFTs = nftStaking.getStakedNFTs(address(this));
        assertEq(stakedNFTs.length, 0);
    }
}