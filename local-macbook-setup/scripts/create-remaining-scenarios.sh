#!/bin/bash

# Quick script to create remaining force close scenario scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Scenario 6: Multiple POs Mixed Status
cat > "$SCRIPT_DIR/force-close-scenario-6.sh" << 'EOF'
#!/bin/bash
# Force Close Scenario 6: Invalid - Multiple POs Mixed Status (NOT ELIGIBLE)
# PO1 Status: For Delivery, PO2 Status: For Approval (mixed status)
# Expected: Button HIDDEN
echo "Scenario 6: Multiple POs Mixed Status - Button HIDDEN"
echo "PO1: For Delivery, PO2: For Approval"
echo "Reason: Mixed PO statuses - least progressed status must be 'For Delivery'"
EOF

# Scenario 7: Cancelled PO
cat > "$SCRIPT_DIR/force-close-scenario-7.sh" << 'EOF'
#!/bin/bash
# Force Close Scenario 7: Invalid - Cancelled PO (NOT ELIGIBLE)
# PO Status: Cancelled
# Expected: Button HIDDEN
echo "Scenario 7: Cancelled PO - Button HIDDEN"
echo "PO Status: Cancelled"
echo "Reason: No active POs with 'For Delivery' status"
EOF

# Scenario 8: Unpaid Deliveries
cat > "$SCRIPT_DIR/force-close-scenario-8.sh" << 'EOF'
#!/bin/bash
# Force Close Scenario 8: Invalid - Unpaid Deliveries (NOT ELIGIBLE)
# Delivery: Partial (Item 7: 60/100, Item 28: 30/50)
# Payment: Unpaid (No PR Created or PR Status not Closed)
# Expected: Button VISIBLE but DISABLED
echo "Scenario 8: Unpaid Deliveries - Button VISIBLE but DISABLED"
echo "Delivery: Partial but unpaid"
echo "Reason: Cannot force close - All delivered items must be paid before force closing"
EOF

# Scenario 9: Auto-Close Detection
cat > "$SCRIPT_DIR/force-close-scenario-9.sh" << 'EOF'
#!/bin/bash
# Force Close Scenario 9: Invalid - Auto-Close Detection (NOT ELIGIBLE)
# All conditions met for automatic closure
# Expected: Button HIDDEN
echo "Scenario 9: Auto-Close Detection - Button HIDDEN"
echo "All POs closed, full delivery, all paid, no remaining quantities"
echo "Reason: Requisition should auto-close - all conditions met for automatic closure"
EOF

# Make all scripts executable
chmod +x "$SCRIPT_DIR/force-close-scenario-6.sh"
chmod +x "$SCRIPT_DIR/force-close-scenario-7.sh"
chmod +x "$SCRIPT_DIR/force-close-scenario-8.sh"
chmod +x "$SCRIPT_DIR/force-close-scenario-9.sh"

echo "✅ Created remaining force close scenario scripts (6-9)"
echo "These are basic placeholders that can be expanded with full database setup"
