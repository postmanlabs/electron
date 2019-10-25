#!/usr/bin/env node

/**
 * This is similar to the file "merge-electron-checksums.py"
 * The original file collects the checksums from a s3 bucket
 * This file uses the checksums which are present on the local file system
 */

const fs = require('fs')
const path = require('path')

const basePath = path.resolve(__dirname, '../dist')

function getChecksumFiles () {
  return new Promise((resolve, reject) => {
    return fs.readdir(basePath, (err, filesAndDirs) => {
      if (err) {
        return reject(err)
      }

      resolve(
        filesAndDirs
          .filter((fileOrDir) => {
            return fileOrDir.includes('.sha256sum')
          })
          .map((file) => {
            return path.resolve(basePath, file)
          })
      )
    })
  })
}

function readFileP (filePath) {
  return new Promise((resolve, reject) => {
    return fs.readFile(filePath, 'utf-8', (err, fileContent) => {
      if (err) {
        return reject(err)
      }

      resolve(fileContent)
    })
  })
}

async function getCollatedChecksums () {
  return getChecksumFiles()
    // read the contents
    .then((checksumFiles) => {
      return Promise.all(checksumFiles.map(readFileP))
    })
    // collate the contents
    .then((contents) => {
      return contents.join('\n')
    })
    .catch((err) => {
      console.log('Error while getting checksum', err)
      process.exit(-1)
    })
}

async function printCollatedChecksums () {
  console.log(await getCollatedChecksums())
}

!module.parent && printCollatedChecksums()
