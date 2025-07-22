const crypto = require('crypto');

/**
 * Emulate PRS password generation algorithm
 * @param {string} secretWord - Usually the username
 * @param {number} timestamp - Optional timestamp (defaults to current time)
 * @param {number} randomNum - Optional random number (defaults to random 0-9999)
 * @returns {string}
 */
function generateSecret(secretWord = '', timestamp = null, randomNum = null) {
  const randomNumber = randomNum !== null ? randomNum : Math.floor(Math.random() * 10000);
  const timeToUse = timestamp !== null ? timestamp : new Date().getTime();

  const cryptoSecret = crypto.createHash('SHA256')
    .update(timeToUse + secretWord)
    .digest('base64');

  return `${randomNumber}#${cryptoSecret}`;
}

/**
 * Generate PRS-style password (first 9 characters of generateSecret)
 * @param {string} username
 * @param {number} timestamp - Optional timestamp
 * @param {number} randomNum - Optional random number
 * @returns {string}
 */
function generatePRSPassword(username, timestamp = null, randomNum = null) {
  const secret = generateSecret(username, timestamp, randomNum);
  return secret.substring(0, 9);
}

/**
 * Simulate password hashing (without bcrypt for demo)
 * @param {string} password
 * @returns {string}
 */
function hashPassword(password) {
  // Simulate bcrypt hash format for demo purposes
  return `$2b$08$${crypto.createHash('sha256').update(password + 'salt').digest('hex').substring(0, 53)}`;
}

/**
 * Convert a given string to PRS password format
 * This simulates creating a password that would result in the given string
 * @param {string} targetPassword - The password you want to achieve
 * @param {string} username - Username to use in generation
 * @returns {object}
 */
function convertToPRSFormat(targetPassword, username) {
  // Since PRS takes first 9 chars, ensure target is 9 chars
  const prsPassword = targetPassword.substring(0, 9);
  const hashedPassword = hashPassword(prsPassword);

  return {
    rawPassword: prsPassword,
    hashedPassword: hashedPassword,
    username: username,
    note: `This simulates storing "${prsPassword}" as a PRS password`
  };
}

/**
 * Reverse engineer: try to find parameters that would generate a specific password
 * Note: This is computationally intensive and may not always find a solution
 * @param {string} targetPassword
 * @param {string} username
 * @param {number} maxAttempts
 * @returns {object|null}
 */
function reverseEngineerPassword(targetPassword, username, maxAttempts = 10000) {
  const target = targetPassword.substring(0, 9);

  for (let randomNum = 0; randomNum < 10000 && randomNum < maxAttempts; randomNum++) {
    // Try different timestamps around current time
    const baseTime = new Date().getTime();
    for (let timeOffset = -1000000; timeOffset <= 1000000; timeOffset += 1000) {
      const timestamp = baseTime + timeOffset;
      const generated = generatePRSPassword(username, timestamp, randomNum);

      if (generated === target) {
        return {
          found: true,
          randomNumber: randomNum,
          timestamp: timestamp,
          generatedPassword: generated,
          hashedPassword: hashPassword(generated)
        };
      }
    }
  }

  return { found: false, message: "Could not reverse engineer the exact parameters" };
}

// Example usage and conversion of your string
console.log("=== PRS Password Creation Emulation ===\n");

// 1. Show how PRS normally generates passwords
console.log("1. Normal PRS password generation for username 'rootuser':");
const normalPassword = generatePRSPassword('rootuser');
console.log(`Generated password: ${normalPassword}`);
console.log(`Hashed: ${hashPassword(normalPassword)}\n`);

// 2. Convert your specific string to PRS format
console.log("2. Converting your string '1490yOVmKW1rootn0' to PRS format:");
const yourString = "1490yOVmKW1rootn0";
const converted = convertToPRSFormat(yourString, 'rootuser');
console.log(`Original string: ${yourString}`);
console.log(`PRS password (first 9 chars): ${converted.rawPassword}`);
console.log(`PRS hashed password: ${converted.hashedPassword}`);
console.log(`Note: ${converted.note}\n`);

// 3. Show the full generateSecret output format
console.log("3. Full generateSecret format example:");
const fullSecret = generateSecret('rootuser');
console.log(`Full secret: ${fullSecret}`);
console.log(`First 9 chars (PRS password): ${fullSecret.substring(0, 9)}\n`);

// 4. Try to reverse engineer (this might take a while and may not find exact match)
console.log("4. Attempting to reverse engineer your string...");
const reverseResult = reverseEngineerPassword(yourString, 'rootuser', 1000);
if (reverseResult.found) {
  console.log("Found matching parameters:");
  console.log(`Random number: ${reverseResult.randomNumber}`);
  console.log(`Timestamp: ${reverseResult.timestamp}`);
  console.log(`Generated: ${reverseResult.generatedPassword}`);
} else {
  console.log(reverseResult.message);
}

// 5. Demonstrate password hashing
console.log("\n5. Password hashing example:");
const testPassword = "1490yOVmK";
const testHash = hashPassword(testPassword);
console.log(`Password: ${testPassword}`);
console.log(`Simulated Hash: ${testHash}`);
console.log(`Note: In real PRS system, this would use bcrypt with salt rounds = 8`);
