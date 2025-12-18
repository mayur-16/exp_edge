# Exp Edge - Backend Structure Documentation

## Database: PostgreSQL (Supabase)
**Provider:** Supabase
**Region:** Singapore (ap-southeast-1)
**Authentication:** Supabase Auth (email/password)

---

## Authentication Flow

### User Authentication
- **Provider:** Supabase Auth (built-in)
- **Method:** Email + Password
- **Storage:** `auth.users` table (managed by Supabase)

### Registration Flow
- **Invite-only:** Users cannot self-register
- **Process:**
  1. Admin creates organization + invite via admin dashboard
  2. Invite token generated with 7-day expiry
  3. User clicks deep link → Opens app
  4. User completes registration with pre-filled org/email
  5. Account created → Auto-login

### Password Reset
- Handled by Supabase Auth
- Admin triggers: `supabase.auth.resetPasswordForEmail(email)`
- User receives email with reset link

---

## Database Tables

### 1. `organizations` (Multi-tenant root)
**Purpose:** Each client company (one subscription per organization)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique organization ID |
| `name` | TEXT | NOT NULL, UNIQUE (case-insensitive) | Company name |
| `email` | TEXT | UNIQUE, NOT NULL | Organization email |
| `phone` | TEXT | NULL | Contact number |
| `subscription_status` | TEXT | CHECK ('trial', 'active', 'expired'), DEFAULT 'trial' | Current subscription state |
| `subscription_plan` | TEXT | CHECK ('trial', 'basic', 'pro'), DEFAULT 'basic' | Plan type |
| `trial_end_date` | TIMESTAMP | NULL | When trial expires |
| `subscription_end_date` | TIMESTAMP | NULL | When paid subscription expires |
| `storage_used` | BIGINT | DEFAULT 0 | Total file storage in bytes |
| `total_sites` | INTEGER | DEFAULT 0 | Auto-updated via trigger |
| `total_expenses` | INTEGER | DEFAULT 0 | Auto-updated via trigger |
| `max_sites` | INTEGER | DEFAULT 50 | Limit for this plan |
| `max_expenses` | INTEGER | DEFAULT 500 | Limit for this plan |
| `max_storage_mb` | INTEGER | DEFAULT 100 | Storage limit in MB |
| `is_active` | BOOLEAN | DEFAULT true | Can org access app? |
| `created_at` | TIMESTAMP | DEFAULT NOW() | When created |

**Indexes:**
- UNIQUE INDEX on `LOWER(name)` (prevents duplicate org names)

**Relationships:**
- 1:N with `users`
- 1:N with `sites`
- 1:N with `vendors`
- 1:N with `expenses`
- 1:N with `invite_tokens`

---

### 2. `users` (User profiles)
**Purpose:** Store user profile information (separate from auth.users)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, REFERENCES auth.users(id) | Links to Supabase Auth |
| `organization_id` | UUID | FOREIGN KEY → organizations(id) CASCADE DELETE | Which org user belongs to |
| `email` | TEXT | NOT NULL | User's email |
| `full_name` | TEXT | NOT NULL | User's display name |
| `role` | TEXT | CHECK ('admin', 'manager', 'accountant'), DEFAULT 'admin' | User role |
| `created_at` | TIMESTAMP | DEFAULT NOW() | When created |

**Indexes:**
- `idx_users_org` on `organization_id`

**Relationships:**
- N:1 with `organizations`
- 1:1 with `auth.users`

**Roles:**
- **admin:** Full access (create, edit, delete everything)
- **manager:** Can add/edit sites, expenses, vendors
- **accountant:** Read-only access

---

### 3. `sites` (Construction sites/projects)
**Purpose:** Track construction sites

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique site ID |
| `organization_id` | UUID | FOREIGN KEY → organizations(id) CASCADE DELETE | Which org owns this |
| `name` | TEXT | NOT NULL | Site name |
| `location` | TEXT | NULL | Address/location |
| `start_date` | DATE | NULL | Project start date |
| `status` | TEXT | CHECK ('active', 'completed', 'on_hold'), DEFAULT 'active' | Site status |
| `created_by` | UUID | FOREIGN KEY → users(id) | Who created it |
| `created_at` | TIMESTAMP | DEFAULT NOW() | When created |

**Indexes:**
- `idx_sites_org` on `organization_id`

**Relationships:**
- N:1 with `organizations`
- 1:N with `expenses`

---

### 4. `vendors` (Suppliers, contractors)
**Purpose:** Track vendors/suppliers

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique vendor ID |
| `organization_id` | UUID | FOREIGN KEY → organizations(id) CASCADE DELETE | Which org owns this |
| `name` | TEXT | NOT NULL | Vendor name |
| `contact_number` | TEXT | NULL | Phone number |
| `email` | TEXT | NULL | Vendor email |
| `address` | TEXT | NULL | Vendor address |
| `vendor_type` | TEXT | CHECK ('material_supplier', 'labor', 'equipment', 'other') | Vendor category |
| `created_at` | TIMESTAMP | DEFAULT NOW() | When created |

**Indexes:**
- `idx_vendors_org` on `organization_id`

**Relationships:**
- N:1 with `organizations`
- 1:N with `expenses` (optional link)

---

### 5. `expenses` (Main transaction table)
**Purpose:** Track all spending per site

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique expense ID |
| `organization_id` | UUID | FOREIGN KEY → organizations(id) CASCADE DELETE | Which org owns this |
| `site_id` | UUID | FOREIGN KEY → sites(id) CASCADE DELETE | Which site |
| `vendor_id` | UUID | FOREIGN KEY → vendors(id) SET NULL | Which vendor (optional) |
| `amount` | DECIMAL(12,2) | NOT NULL, CHECK (>= 0) | Money spent |
| `description` | TEXT | NOT NULL | What was purchased |
| `category` | TEXT | CHECK ('labor', 'materials', 'equipment', 'transport', 'other') | Expense category |
| `expense_date` | DATE | NOT NULL | When expense occurred |
| `receipt_url` | TEXT | NULL | Link to receipt photo in storage |
| `receipt_file_size` | BIGINT | DEFAULT 0 | File size in bytes |
| `created_by` | UUID | FOREIGN KEY → users(id) | Who created it |
| `created_at` | TIMESTAMP | DEFAULT NOW() | When created |
| `updated_at` | TIMESTAMP | DEFAULT NOW() | Last modified |
| `synced` | BOOLEAN | DEFAULT true | For offline sync |
| `device_id` | TEXT | NULL | For offline tracking |

**Indexes:**
- `idx_expenses_org` on `organization_id`
- `idx_expenses_site` on `site_id`
- `idx_expenses_date` on `expense_date`

**Relationships:**
- N:1 with `organizations`
- N:1 with `sites`
- N:1 with `vendors` (optional)

---

### 6. `audit_logs` (Activity tracking)
**Purpose:** Track who did what (for accountability)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique log ID |
| `organization_id` | UUID | FOREIGN KEY → organizations(id) CASCADE DELETE | Which org |
| `user_id` | UUID | FOREIGN KEY → users(id) | Who performed action |
| `action` | TEXT | NOT NULL | Action type |
| `entity_type` | TEXT | NULL | 'site', 'expense', 'vendor', 'user' |
| `entity_id` | UUID | NULL | ID of affected record |
| `old_values` | JSONB | NULL | Data before change |
| `new_values` | JSONB | NULL | Data after change |
| `created_at` | TIMESTAMP | DEFAULT NOW() | When action occurred |

**Indexes:**
- `idx_audit_logs_org` on `organization_id`

---

### 7. `invite_tokens` (Invite system)
**Purpose:** Manage user invitations

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Unique invite ID |
| `organization_id` | UUID | FOREIGN KEY → organizations(id) CASCADE DELETE | Which org |
| `email` | TEXT | NOT NULL | Invited user's email |
| `token` | TEXT | UNIQUE, NOT NULL | Invite token |
| `role` | TEXT | CHECK ('admin', 'manager', 'accountant'), DEFAULT 'admin' | Assigned role |
| `expires_at` | TIMESTAMP | NOT NULL | Token expiry (7 days) |
| `used` | BOOLEAN | DEFAULT false | Has token been used? |
| `created_at` | TIMESTAMP | DEFAULT NOW() | When created |

**Indexes:**
- `idx_invite_tokens_token` on `token`
- `idx_invite_tokens_email` on `email`

---

## Row Level Security (RLS)

**All tables have RLS enabled.**

### Multi-Tenancy Isolation
Every query automatically filters by `organization_id`:
```sql
-- Example: Users can only see their organization's expenses
CREATE POLICY "Users access own expenses" ON expenses
  FOR ALL USING (
    organization_id IN (
      SELECT organization_id FROM users WHERE id = auth.uid()
    )
  );
```

**Effect:** Users **cannot** see other organizations' data, even if they modify the app code.

### Policy Summary
| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `organizations` | Own org only | Via invite | Own org admins | Via admin dashboard |
| `users` | Own org only | Via invite | Self only | Via admin dashboard |
| `sites` | Own org only | Managers+ | Managers+ | Admins only |
| `vendors` | Own org only | Managers+ | Managers+ | Admins only |
| `expenses` | Own org only | Managers+ | Managers+ | Managers+ |
| `audit_logs` | Own org only | Automatic | None | None |
| `invite_tokens` | Own email | Via admin | None | Automatic |

---

## Database Functions

### 1. `update_org_stats()`
**Purpose:** Auto-update organization usage statistics

**Trigger:** Fires AFTER INSERT/DELETE on `sites` and `expenses`

**Logic:**
```sql
- When site added/deleted → Updates organizations.total_sites
- When expense added/deleted → Updates organizations.total_expenses
- When receipt uploaded → Updates organizations.storage_used
```

### 2. `generate_invite_token()`
**Purpose:** Generate random URL-safe invite token

**Returns:** TEXT (32-character token)

**Usage:** Called when admin creates invite

### 3. `validate_invite_token(token_input TEXT)`
**Purpose:** Check if invite token is valid

**Returns:** TABLE with:
- `is_valid` (boolean)
- `organization_id` (UUID)
- `organization_name` (TEXT)
- `email` (TEXT)
- `role` (TEXT)

**Logic:**
- Checks if token exists
- Checks if not expired (`expires_at > NOW()`)
- Checks if not used (`used = false`)

### 4. `check_subscription_access(org_id UUID)`
**Purpose:** Verify if organization can access app

**Returns:** BOOLEAN

**Logic:**
- If trial → check `trial_end_date`
- If active → check `subscription_end_date`
- If expired → return false
- Auto-updates status if expired

---

## Storage Buckets

### `receipts` (Private)
**Purpose:** Store expense receipt photos

**Structure:**
```
receipts/
  {organization_id}/
    {timestamp}.jpg
```

**Access Control:**
- Users can upload to their org folder only
- Users can view their org receipts only
- Files deleted when expense deleted

**Policies:**
```sql
- INSERT: organization_id matches user's org
- SELECT: organization_id matches user's org
- DELETE: organization_id matches user's org
```

---

## API Endpoints (via Supabase)

All accessed via Supabase client in Flutter.

### Pagination
```dart
.select()
.range(offset, offset + limit - 1)
.count(CountOption.exact)
```

### Search
```dart
.or('name.ilike.%query%,location.ilike.%query%')
```

### Filtering
```dart
.eq('organization_id', orgId)
.eq('site_id', siteId)
```

---

## Subscription Logic

### Trial Period
- **Duration:** 14 days (configurable by admin)
- **Status:** 'trial'
- **Starts:** On organization creation
- **Warning:** Shows at day 12 (3 days before expiry)

### Active Subscription
- **Status:** 'active'
- **Duration:** Set by admin (30/90/365 days)
- **Renewable:** Admin extends via dashboard

### Expired
- **Status:** 'expired'
- **Access:** Blocked completely
- **Data:** Retained (not deleted)
- **Recovery:** Admin reactivates

### Access Control Flow
```
1. User opens app
2. Check subscription_status:
   - If 'trial' → Check trial_end_date
   - If 'active' → Check subscription_end_date
   - If 'expired' → Block access
3. If expired → Update status to 'expired'
4. If days_left <= 3 → Show warning
```

---

## Data Export

### Excel Export (Client-side)
**Location:** Flutter app using `excel` package

**Formats:**
1. **Expenses:** Date, Site, Vendor, Category, Amount, Receipt
   - Includes: Total, Category summary
2. **Sites:** Name, Location, Start Date, Status
3. **Vendors:** Name, Type, Contact, Email, Address

**Trigger:** Manual via app (Profile screen or Expenses tab)

---

## Backend Limitations & Quotas

### Supabase Free Tier (for testing)
- 500 MB database storage
- 1 GB file storage
- 50,000 monthly active users
- 2 GB bandwidth

### Production Tier
- Unlimited database storage
- 100 GB file storage included
- Unlimited users
- 250 GB bandwidth

### Per Organization Limits (App-defined)
| Plan | Max Sites | Max Expenses | Max Storage |
|------|-----------|--------------|-------------|
| Trial | 50 | 500 | 100 MB |
| Basic | 100 | 2,000 | 500 MB |
| Pro | Unlimited | Unlimited | 2 GB |

---

## Security Measures

1. ✅ **Row Level Security (RLS):** All tables isolated by organization
2. ✅ **Invite-only registration:** No public signup
3. ✅ **Token expiry:** Invites expire in 7 days
4. ✅ **Single-use tokens:** Cannot reuse invite links
5. ✅ **Duplicate prevention:** Organization names must be unique
6. ✅ **Password hashing:** Handled by Supabase Auth (bcrypt)
7. ✅ **SSL/TLS:** All connections encrypted
8. ✅ **Biometric auth:** Optional fingerprint/Face ID
9. ✅ **Audit logging:** All actions tracked

---

## Backup & Recovery

### Automated Backups (Supabase Pro)
- **Frequency:** Daily
- **Retention:** 7 days
- **Location:** Supabase managed

### Manual Export
Admin can export via Supabase dashboard:
- Full database dump (SQL)
- CSV exports per table

### Data Retention Policy
- **Active subscriptions:** All data retained
- **Expired (1-30 days):** Data retained, access blocked
- **Expired (31-90 days):** Data archived, available on request
- **Expired (90+ days):** Data deleted with warning

---

## Environment Variables

### Mobile App (.env file)
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
```

### Admin Dashboard
```dart
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...  // Admin privileges
```

---

## Deep Links

**Scheme:** `expedge://`

**Invite Link Format:**
```
expedge://invite/{token}
```

**Example:**
```
expedge://invite/abc123xyz456
```

**Behavior:**
- Opens mobile app (if installed)
- Navigates to invite registration screen
- Pre-fills org and email
- User completes name and password

---

## Future Enhancements (Not Implemented)

- [ ] Email notifications for expiry warnings
- [ ] SMS verification
- [ ] Two-factor authentication
- [ ] Offline mode with sync queue
- [ ] Real-time collaboration
- [ ] Advanced analytics dashboard
- [ ] Automated invoice generation
- [ ] Integration with accounting software

---

## Contact & Support

**Database Provider:** Supabase
**Region:** Singapore (ap-southeast-1)
**Admin Dashboard:** Flutter Web (macOS app)
**Mobile App:** Flutter (iOS & Android)

---

**Last Updated:** December 2024
**Version:** 1.0.0