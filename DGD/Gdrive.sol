// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedFileSharing {
  event FileUploaded(address indexed uploader, string fileHash, string folderPath);
  event FileCopied(address indexed copier, string originalFileHash, string copiedFileHash, string fromFolder, string toFolder);

  struct File {
    address uploader;
    string fileHash;
    uint256 _version;
  }

  mapping(string => File) public files;
  mapping(string => string[]) public folders;

  function removeElement(string[] storage arr, string memory element) internal {
    for (uint256 i = 0; i < arr.length; i++) {
      if (keccak256(abi.encodePacked(arr[i])) == keccak256(abi.encodePacked(element))) {
        arr[i] = arr[arr.length - 1];
        arr.pop();
        break;
      }
    }
  }

  function uploadFile(string memory _fileHash, uint256 _version, string memory _folderPath) external {
    require(bytes(_fileHash).length > 0, "File hash cannot be empty");
    files[_fileHash] = File(msg.sender, _fileHash, _version);
    folders[_folderPath].push(_fileHash);
    emit FileUploaded(msg.sender, _fileHash, _folderPath);
  }

  function deleteFile(string memory _fileHash, string memory _folderPath) external {
    require(bytes(files[_fileHash].fileHash).length > 0, "File not found");
    require(files[_fileHash].uploader == msg.sender, "Unauthorized deletion");

    delete files[_fileHash];
    removeElement(folders[_folderPath], _fileHash);
  }

  function downloadFile(string memory _fileHash) external view returns (address uploader, string memory fileHash) {
    File storage file = files[_fileHash];
    require(bytes(file.fileHash).length > 0, "File not found");
    return (file.uploader, file.fileHash);
  }

  function getFilesInFolder(string memory _folderPath) external view returns (string[] memory) {
    return folders[_folderPath];
  }

  function moveFile(string memory _fileHash, string memory _fromFolder, string memory _toFolder) external {
    require(bytes(files[_fileHash].fileHash).length > 0, "File not found");

    bool foundInFromFolder = false;
    for (uint256 i = 0; i < folders[_fromFolder].length; i++) {
      if (keccak256(abi.encodePacked(folders[_fromFolder][i])) == keccak256(abi.encodePacked(_fileHash))) {
        foundInFromFolder = true;
        break;
      }
    }
    require(foundInFromFolder, "File not found in the source folder");

    removeElement(folders[_fromFolder], _fileHash);
    folders[_toFolder].push(_fileHash);
  }

  // New function to copy a file with a new name
  function copyFile(string memory _fileHash, string memory _newFileName, string memory _fromFolder, string memory _toFolder) external {
    require(bytes(files[_fileHash].fileHash).length > 0, "File not found");
    require(bytes(_newFileName).length > 0, "New file name cannot be empty");

    // Check if file exists in the from folder
    bool foundInFromFolder = false;
    for (uint256 i = 0; i < folders[_fromFolder].length; i++) {
      if (keccak256(abi.encodePacked(folders[_fromFolder][i])) == keccak256(abi.encodePacked(_fileHash))) {
        foundInFromFolder = true;
        break;
      }
    }
    require(foundInFromFolder, "File not found in the source folder");

    // Generate new file hash using keccak256 hash of concatenation of new file name and current timestamp
    string memory newFileHash = string(abi.encodePacked(_newFileName, block.timestamp));

    // Copy file details to the new file hash
    files[newFileHash] = File(msg.sender, newFileHash, files[_fileHash]._version);

    // Add new file to the destination folder
    folders[_toFolder].push(newFileHash);

    emit FileCopied(msg.sender, _fileHash, newFileHash, _fromFolder, _toFolder);
  }
}