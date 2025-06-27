/**
 * Script to run all tests sequentially to avoid port conflicts
 */
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// Get the project root directory
const projectRoot = path.resolve(__dirname, '..');

// Helper function to run a Jest command
function runJest(testPattern, options = {}) {
  const { setupFile = './tests/setup/dbMock.js', silent = false } = options;
  
  const command = `npx jest ${testPattern} --setupFilesAfterEnv ${setupFile}`;
  console.log(`\n\n========== Running: ${command} ==========\n`);
  
  try {
    const output = execSync(command, { 
      cwd: projectRoot,
      stdio: silent ? 'pipe' : 'inherit'
    });
    
    if (silent) {
      return output.toString();
    }
    return true;
  } catch (error) {
    console.error(`Error running tests: ${error.message}`);
    if (silent) {
      return error.output ? error.output.toString() : '';
    }
    return false;
  }
}

// Run the tests in sequence
(async () => {
  console.log('Starting tests...');
  
  // Run integration tests one by one
  const integrationTestResults = {};
  const integrationTestFiles = [
    'tests/integration/auth.test.js',
    'tests/integration/health.test.js'
  ];
  
  for (const testFile of integrationTestFiles) {
    const result = runJest(testFile);
    integrationTestResults[testFile] = result;
  }
  
  // Finally run the unit tests
  const unitTestResult = runJest('tests/unit/');
  
  console.log('\n\n========== Test Summary ==========\n');
  let allPassed = true;
  
  for (const [testFile, result] of Object.entries(integrationTestResults)) {
    console.log(`${testFile}: ${result ? '✅ Passed' : '❌ Failed'}`);
    if (!result) allPassed = false;
  }
  
  console.log(`Unit tests: ${unitTestResult ? '✅ Passed' : '❌ Failed'}`);
  if (!unitTestResult) allPassed = false;
  
  if (allPassed) {
    console.log('\n✅ All tests passed!');
    process.exit(0);
  } else {
    console.log('\n❌ Some tests failed');
    process.exit(1);
  }
})();
