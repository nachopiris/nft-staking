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

        NFTStaking.NftInput[] memory nfts = new NFTStaking.NftInput[](1);
        nfts[0] = NFTStaking.NftInput(address(erc721), 1, 1);

        nftStaking.stake(nfts);

        NFTStaking.NftInfo[] memory stakedNFTs = nftStaking.getStakedNFTs(address(this));
        assertEq(stakedNFTs.length, 1);
        assertEq(stakedNFTs[0].contractAddress, address(erc721));
        assertEq(stakedNFTs[0].tokenId, 1);
        assertEq(stakedNFTs[0].amount, 1);
        assertTrue(stakedNFTs[0].isERC721);
    }

    function testStakeERC1155() public {
        erc1155.mint(address(this), 1, 5);
        erc1155.setApprovalForAll(address(nftStaking), true);

        NFTStaking.NftInput[] memory nfts = new NFTStaking.NftInput[](1);
        nfts[0] = NFTStaking.NftInput(address(erc1155), 1, 5);

        nftStaking.stake(nfts);

        NFTStaking.NftInfo[] memory stakedNFTs = nftStaking.getStakedNFTs(address(this));
        assertEq(stakedNFTs.length, 1);
        assertEq(stakedNFTs[0].contractAddress, address(erc1155));
        assertEq(stakedNFTs[0].tokenId, 1);
        assertEq(stakedNFTs[0].amount, 5);
        assertFalse(stakedNFTs[0].isERC721);
    }

    function testUnstakeAll() public {
        erc721.mint(address(this), 1);
        erc721.approve(address(nftStaking), 1);

        NFTStaking.NftInput[] memory nfts = new NFTStaking.NftInput[](1);
        nfts[0] = NFTStaking.NftInput(address(erc721), 1, 1);

        nftStaking.stake(nfts);
        nftStaking.unstakeAll();

        NFTStaking.NftInfo[] memory stakedNFTs = nftStaking.getStakedNFTs(address(this));
        assertEq(stakedNFTs.length, 0);
    }
}