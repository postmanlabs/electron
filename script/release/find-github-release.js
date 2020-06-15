if (!process.env.CI) require('dotenv-safe').load();

const octokit = require('@octokit/rest')({
  auth: process.env.ELECTRON_GITHUB_TOKEN
});

if (process.argv.length < 3) {
  console.log('Usage: find-release version');
  process.exit(1);
}

const version = process.argv[2];
const owner = 'postmanlabs';

async function findRelease () {
  const releases = await octokit.repos.listReleases({
    owner,
    repo: version.indexOf('nightly') > 0 ? 'nightlies' : 'electron'
  });

  const targetRelease = releases.data.find(release => release.tag_name === version);
  let returnObject = {};

  if (targetRelease) {
    returnObject = {
      id: targetRelease.id,
      draft: targetRelease.draft,
      exists: true
    };
  } else {
    returnObject = {
      exists: false,
      draft: false
    };
  }

  console.log(JSON.stringify(returnObject));
}

findRelease();
