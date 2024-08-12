// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract NFTStaking is ERC1155Holder {
    struct Nft {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
    }

    mapping(address => mapping(address => mapping(uint256 => uint256))) private stakedNfts;

    mapping(address => address[]) private userTokenContracts;
    mapping(address => mapping(address => uint256[])) private userTokenIds;

    event NftsStaked(address indexed user, Nft[] nfts);
    event NftsUnstaked(address indexed user, Nft[] nfts);

    function stake(Nft[] calldata _nfts) external {
        require(_nfts.length > 0, "Must stake at least one NFT");

        for (uint256 i = 0; i < _nfts.length; i++) {
            Nft memory nft = _nfts[i];

            require(nft.amount > 0, "Amount must be greater than 0");

            IERC1155(nft.contractAddress).safeTransferFrom(
                msg.sender,
                address(this),
                nft.tokenId,
                nft.amount,
                ""
            );

            if (stakedNfts[msg.sender][nft.contractAddress][nft.tokenId] == 0) {
                userTokenIds[msg.sender][nft.contractAddress].push(nft.tokenId);
                if (userTokenIds[msg.sender][nft.contractAddress].length == 1) {
                   userTokenContracts[msg.sender].push(nft.contractAddress);
                }
            }

            stakedNfts[msg.sender][nft.contractAddress][nft.tokenId] += nft.amount;
        }

        emit NftsStaked(msg.sender, _nfts);
    }

    function unstake(Nft[] calldata _nfts) external {
        require(_nfts.length > 0, "Must unstake at least one NFT");

        for (uint256 i = 0; i < _nfts.length; i++) {
            Nft memory nft = _nfts[i];

            require(nft.amount > 0, "Amount must be greater than 0");

            uint256 stakedNftAmount = stakedNfts[msg.sender][nft.contractAddress][nft.tokenId];

            require(stakedNftAmount >= nft.amount, "Insufficient staked amount");

            stakedNfts[msg.sender][nft.contractAddress][nft.tokenId] -= nft.amount;

            if (stakedNfts[msg.sender][nft.contractAddress][nft.tokenId] == 0) {
                if (_removeTokenId(msg.sender, nft.contractAddress, nft.tokenId)) {
                    _removeTokenContract(msg.sender, nft.contractAddress);
                }
            }

            IERC1155(nft.contractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                nft.tokenId,
                nft.amount,
                ""
            );
        }

        emit NftsUnstaked(msg.sender, _nfts);
    }

    function _removeTokenId(address _user, address _tokenContract, uint256 _tokenId) internal returns (bool) {
        uint256[] storage tokenIds = userTokenIds[_user][_tokenContract];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == _tokenId) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                return tokenIds.length == 0;
            }
        }
        return false;
    }

    function _removeTokenContract(address _user, address _tokenContract) internal {
        address[] storage tokenContracts = userTokenContracts[_user];
        for (uint256 i = 0; i < tokenContracts.length; i++) {
            if (tokenContracts[i] == _tokenContract) {
                tokenContracts[i] = tokenContracts[tokenContracts.length - 1];
                tokenContracts.pop();
                break;
            }
        }
    }

    function getUserTokenIds(address _user, address _tokenContract) external view returns (uint256[] memory) {
        return userTokenIds[_user][_tokenContract];
    }

    function getUserTokenContracts(address _user) external view returns (address[] memory) {
        return userTokenContracts[_user];
    }

    function getStakedNFTs(address _user) external view returns (Nft[] memory nfts) {
        uint256 count = 0;

        for (uint256 i = 0; i < userTokenContracts[_user].length; i++) {
            address tokenContract = userTokenContracts[_user][i];
            for (uint256 j = 0; j < userTokenIds[_user][tokenContract].length; j++) {
                uint256 tokenId = userTokenIds[_user][tokenContract][j];
                if (stakedNfts[_user][tokenContract][tokenId] > 0) {
                    count++;
                }
            }
        }

        nfts = new Nft[](count);

        uint256 index = 0;
        for (uint256 i = 0; i < userTokenContracts[_user].length; i++) {
            address tokenContract = userTokenContracts[_user][i];
            for (uint256 j = 0; j < userTokenIds[_user][tokenContract].length; j++) {
                uint256 tokenId = userTokenIds[_user][tokenContract][j];
                if (stakedNfts[_user][tokenContract][tokenId] > 0) {
                    nfts[index] = Nft(
                        tokenContract,
                        tokenId,
                        stakedNfts[_user][tokenContract][tokenId]
                    );
                    index++;
                }
            }
        }
    }
}
