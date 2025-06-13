# Force Close Testing Guide - Tasks 1.0 & 2.0

This guide provides comprehensive testing instructions for the Force Close functionality implemented in Tasks 1.0 and 2.0.

## 🎯 What We're Testing

### Task 1.0 - Critical Infrastructure
- ✅ Force close services registration (auto-loading)
- ✅ ForceCloseRepository with transaction-wrapped operations
- ✅ Database schema with all required tracking fields
- ✅ Scenario handling (3 scenarios aligned with requirements)

### Task 2.0 - API Alignment
- ✅ Updated API endpoints structure (`/api/requisitions/{id}/...`)
- ✅ Request/response schemas matching requirements
- ✅ Dual validation paths (Active PO vs Closed PO)
- ✅ Enhanced error handling and validation

## 🚀 Quick Start Testing

### 1. Start the Local Environment

```bash
cd /Users/ronalddelacruz/Documents/augment-projects/prs/prs-production-deployment/local-macbook-setup

# Start all services
./scripts/deploy-local.sh start

# Check status
./scripts/deploy-local.sh status
```

### 2. Run Database Migrations

```bash
# Apply force close schema migrations
./scripts/deploy-local.sh exec backend npm run migrate

# Verify migrations applied
./scripts/deploy-local.sh exec backend npm run migrate:status
```

### 3. Run API Tests

```bash
# Run comprehensive force close API tests
./test-force-close-api.sh
```

## 📋 Detailed Testing Procedures

### Unit Tests (Backend)

```bash
cd prs-backend

# Run force close specific tests
npx mocha test/unit/src/app/services/forceCloseService.spec.js
npx mocha test/unit/src/infra/repositories/forceCloseRepository.spec.js
npx mocha test/unit/src/app/handlers/controllers/forceCloseController.spec.js
npx mocha test/unit/src/interfaces/forceCloseRoutes.spec.js
npx mocha test/unit/src/infra/database/migrations/force-close-schema.spec.js

# Run all force close tests
npx mocha --grep "ForceClose"
```

### API Integration Tests

The `test-force-close-api.sh` script tests:

1. **Force Close Validation** (`POST /api/requisitions/{id}/validate-force-close`)
   - Checks eligibility and scenario determination
   - Tests dual validation paths
   - Validates business logic

2. **Force Close Execution** (`POST /api/requisitions/{id}/force-close`)
   - Tests complete force close workflow
   - Validates new request schema (notes, confirmedScenario, acknowledgedImpacts)
   - Checks response format

3. **Force Close History** (`GET /api/requisitions/{id}/force-close-history`)
   - Retrieves audit trail and system changes
   - Tests history endpoint functionality

4. **Schema Validation**
   - Empty notes validation
   - Invalid scenario validation
   - Missing required fields
   - Invalid requisition ID handling

### Database Testing

```bash
# Connect to database
./scripts/deploy-local.sh exec postgres psql -U prs_user -d prs_local

# Check force close schema
\d requisitions
\d force_close_logs
\d invoice_reports
\d delivery_receipts
\d rs_payment_requests

# Verify indices
\di *force*
\di *cancel*
```

## 🔍 Test Scenarios

### Scenario 1: Active PO with Partial Delivery
```sql
-- Create test data for Scenario 1
INSERT INTO requisitions (id, status, ...) VALUES (1, 'APPROVED', ...);
INSERT INTO purchase_orders (id, requisition_id, status, ...) VALUES (1, 1, 'FOR_DELIVERY', ...);
INSERT INTO delivery_receipts (id, purchase_order_id, status, ...) VALUES (1, 1, 'DR_APPROVED', ...);
-- Partial delivery data
```

### Scenario 2: Closed PO with Remaining Quantities
```sql
-- Create test data for Scenario 2
INSERT INTO purchase_orders (id, requisition_id, status, ...) VALUES (2, 1, 'CLOSED', ...);
-- Remaining quantities data
```

### Scenario 3: Closed PO with Pending CS
```sql
-- Create test data for Scenario 3
INSERT INTO canvass_requisitions (id, requisition_id, status, ...) VALUES (1, 1, 'CS_PENDING_APPROVAL', ...);
```

## 📊 Expected Test Results

### ✅ Successful Test Indicators

1. **API Tests Pass:**
   - Status 200 for validation endpoint
   - Status 200 for execution endpoint (with valid data)
   - Status 200 or 404 for history endpoint
   - Status 400 for validation errors (expected)

2. **Database Schema:**
   - All force close tables exist
   - All cancellation fields added
   - Indices created for performance

3. **Service Integration:**
   - Services auto-loaded by container
   - Repository operations work with transactions
   - Scenario logic follows requirements

### ❌ Common Issues and Solutions

1. **404 Endpoint Not Found**
   ```bash
   # Check route registration
   ./scripts/deploy-local.sh logs backend | grep -i "route\|force"
   ```

2. **Database Connection Issues**
   ```bash
   # Check database status
   ./scripts/deploy-local.sh status
   ./scripts/deploy-local.sh logs postgres
   ```

3. **Authentication Failures**
   ```bash
   # Check if admin user exists
   ./scripts/deploy-local.sh exec backend npm run seed:dev
   ```

4. **Migration Issues**
   ```bash
   # Check migration status
   ./scripts/deploy-local.sh exec backend npm run migrate:status
   
   # Rollback and retry if needed
   ./scripts/deploy-local.sh exec backend npm run migrate:undo
   ./scripts/deploy-local.sh exec backend npm run migrate
   ```

## 🎯 Success Criteria

### Task 1.0 Infrastructure ✅
- [ ] All unit tests pass
- [ ] Database migrations apply successfully
- [ ] Force close services are auto-loaded
- [ ] Repository operations work with transactions
- [ ] All 3 scenarios are properly implemented

### Task 2.0 API Alignment ✅
- [ ] All API endpoints respond correctly
- [ ] Request/response schemas match requirements
- [ ] Dual validation paths work correctly
- [ ] Error handling is comprehensive
- [ ] API structure follows requirements document

## 🚀 Next Steps

Once all tests pass:

1. **Verify in Frontend UI**
   - Access https://localhost:8443
   - Navigate to requisition details
   - Test force close button functionality

2. **Performance Testing**
   - Test with larger datasets
   - Verify transaction performance
   - Check database query efficiency

3. **Proceed to Task 3.0**
   - Payment prerequisite validation
   - Enhanced business logic
   - Additional scenario handling

## 📞 Troubleshooting

If tests fail:

1. Check backend logs: `./scripts/deploy-local.sh logs backend`
2. Check database logs: `./scripts/deploy-local.sh logs postgres`
3. Verify service status: `./scripts/deploy-local.sh status`
4. Check container health: `docker ps`
5. Review migration status: `./scripts/deploy-local.sh exec backend npm run migrate:status`

For detailed debugging, enable debug logs:
```bash
# Set debug environment
echo "LOG_LEVEL=debug" >> .env
echo "ENABLE_DEBUG_LOGS=true" >> .env

# Restart services
./scripts/deploy-local.sh restart
```
