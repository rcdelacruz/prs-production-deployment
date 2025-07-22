const bcrypt = require('bcrypt');

// Your original string
const originalString = "1490yOVmKW1rootn0";

// PRS format (first 9 characters)
const prsPassword = originalString.substring(0, 9);

// Generate bcrypt hash with salt rounds = 8 (PRS standard)
const hashedPassword = bcrypt.hashSync(prsPassword, 8);

console.log("=== PRS Password Hash Generation ===");
console.log(`Original string: ${originalString}`);
console.log(`PRS password: ${prsPassword}`);
console.log(`Bcrypt hash: ${hashedPassword}`);
console.log("\n=== Database Storage ===");
console.log(`password = '${hashedPassword}'`);
console.log(`tempPass = '${prsPassword}'`);
console.log(`isPasswordTemporary = true`);
