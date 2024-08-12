// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTStaking.sol";
import "./mocks/MockERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract NFTStakingTest is ERC1155Holder, Test {
    NFTStaking nftStaking;
    MockERC1155 erc1155;

    function setUp() public {
        nftStaking = new NFTStaking();
        erc1155 = new MockERC1155();
    }

    function testStakeERC1155() public {
        erc1155.mint(address(this), 1, 5);
        erc1155.setApprovalForAll(address(nftStaking), true);

        NFTStaking.Nft[] memory nfts = new NFTStaking.Nft[](1);
        nfts[0] = NFTStaking.Nft(address(erc1155), 1, 5);

        nftStaking.stake(nfts);

        NFTStaking.Nft[] memory stakedNFTs = nftStaking.getStakedNFTs(
            address(this)
        );
        uint256[] memory userTokenIds = nftStaking.getUserTokenIds(address(this), address(erc1155));
        address[] memory userTokenContracts = nftStaking.getUserTokenContracts(address(this));


        assertEq(stakedNFTs.length, 1);
        assertEq(stakedNFTs[0].contractAddress, address(erc1155));
        assertEq(stakedNFTs[0].tokenId, 1);
        assertEq(stakedNFTs[0].amount, 5);
        assertEq(userTokenIds[0], 1);
        assertEq(userTokenContracts[0], address(erc1155));

    }

    function testUnstake() public {
        erc1155.mint(address(this), 1, 5);
        erc1155.setApprovalForAll(address(nftStaking), true);

        NFTStaking.Nft[] memory nfts = new NFTStaking.Nft[](1);
        nfts[0] = NFTStaking.Nft(address(erc1155), 1, 5);

        nftStaking.stake(nfts);

        nfts[0] = NFTStaking.Nft(address(erc1155), 1, 3);

        nftStaking.unstake(nfts);

        NFTStaking.Nft[] memory stakedNFTs = nftStaking.getStakedNFTs(
            address(this)
        );
        uint256[] memory userTokenIds = nftStaking.getUserTokenIds(address(this), address(erc1155));
        address[] memory userTokenContracts = nftStaking.getUserTokenContracts(address(this));

        assertEq(stakedNFTs.length, 1);
        assertEq(userTokenIds[0], 1);
        assertEq(userTokenContracts[0], address(erc1155));
    }
}
