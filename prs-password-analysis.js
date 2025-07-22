const crypto = require('crypto');

console.log("=== PRS Password Creation Analysis ===\n");

// Your original string
const yourString = "1490yOVmKW1rootn0";
console.log(`Your original string: "${yourString}"`);
console.log(`Length: ${yourString.length} characters\n`);

// PRS Password Conversion
console.log("=== Converting to PRS Format ===");
const prsPassword = yourString.substring(0, 9);
console.log(`PRS password (first 9 chars): "${prsPassword}"`);

// Simulate the hashing process
function simulateBcryptHash(password) {
  // This simulates bcrypt format but isn't actual bcrypt
  const hash = crypto.createHash('sha256').update(password + 'prs_salt_simulation').digest('hex');
  return `$2b$08$${hash.substring(0, 53)}`;
}

const hashedPassword = simulateBcryptHash(prsPassword);
console.log(`Simulated bcrypt hash: "${hashedPassword}"\n`);

// Show how PRS actually generates passwords
console.log("=== How PRS Actually Generates Passwords ===");

function generateSecret(secretWord = '', timestamp = null, randomNum = null) {
  const randomNumber = randomNum !== null ? randomNum : Math.floor(Math.random() * 10000);
  const timeToUse = timestamp !== null ? timestamp : new Date().getTime();
  
  const cryptoSecret = crypto.createHash('SHA256')
    .update(timeToUse + secretWord)
    .digest('base64');

  return `${randomNumber}#${cryptoSecret}`;
}

// Generate a few examples
console.log("Examples of PRS password generation:");
for (let i = 0; i < 3; i++) {
  const fullSecret = generateSecret('rootuser');
  const password = fullSecret.substring(0, 9);
  console.log(`Full secret: ${fullSecret}`);
  console.log(`Password: ${password}\n`);
}

// Analyze your string structure
console.log("=== Analysis of Your String Structure ===");
console.log(`Your string: "${yourString}"`);
console.log("Breakdown:");
console.log(`- First 4 chars: "${yourString.substring(0, 4)}" (could be random number)`);
console.log(`- Next 5 chars: "${yourString.substring(4, 9)}" (part of hash)`);
console.log(`- Remaining: "${yourString.substring(9)}" (would be truncated in PRS)`);

// Check if it follows PRS pattern
const hasHashSymbol = yourString.includes('#');
console.log(`\nContains '#' symbol: ${hasHashSymbol}`);
if (hasHashSymbol) {
  const parts = yourString.split('#');
  console.log(`Random number part: "${parts[0]}"`);
  console.log(`Hash part: "${parts[1]}"`);
} else {
  console.log("Does not follow exact PRS generateSecret format (missing '#')");
}

// Show what would happen in PRS database
console.log("\n=== What Would Be Stored in PRS Database ===");
console.log("User record would contain:");
console.log(`- username: "rootuser" (example)`);
console.log(`- password: "${hashedPassword}" (bcrypt hash)`);
console.log(`- tempPass: "${prsPassword}" (temporary, for password reset)`);
console.log(`- isPasswordTemporary: true`);

// Show the exact PRS algorithm step by step
console.log("\n=== PRS Algorithm Step by Step ===");
const username = "rootuser";
const timestamp = new Date().getTime();
const randomNum = 1490; // Using your first 4 digits

console.log(`1. Input username: "${username}"`);
console.log(`2. Generate random number: ${randomNum} (0-9999)`);
console.log(`3. Get timestamp: ${timestamp}`);
console.log(`4. Create hash input: ${timestamp + username}`);

const hashInput = timestamp + username;
const sha256Hash = crypto.createHash('SHA256').update(hashInput).digest('base64');
console.log(`5. SHA256 hash: ${sha256Hash}`);

const fullSecret = `${randomNum}#${sha256Hash}`;
console.log(`6. Full secret: ${fullSecret}`);

const finalPassword = fullSecret.substring(0, 9);
console.log(`7. Final password (first 9 chars): "${finalPassword}"`);

console.log("\n=== Summary ===");
console.log(`Your string "${yourString}" converted to PRS format:`);
console.log(`✓ Raw password: "${prsPassword}"`);
console.log(`✓ Would be hashed with bcrypt (salt rounds: 8)`);
console.log(`✓ Stored as temporary password requiring user to change on first login`);
console.log(`✓ Length: 9 characters (PRS standard)`);
