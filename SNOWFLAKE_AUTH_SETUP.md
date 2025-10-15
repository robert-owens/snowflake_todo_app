# Snowflake Authentication Setup
j
This guide explains how to set up authentication for both local development and Snowpark Container deployment.

## Authentication Methods (Priority Order)

1. **Session Token** (Snowpark Container Services - automatic)
2. **Key-Pair Authentication** (Recommended for local development)
3. **Password Authentication** (Fallback only)

---

## For Local Development: Key-Pair Authentication

### Step 1: Generate RSA Key Pair

```bash
# Generate private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt

# Generate public key
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
```

### Step 2: Add Public Key to Snowflake

```sql
-- In Snowflake SQL console, run:
ALTER USER ROBERT.L.OWENS@ADVOCATEHEALTH.ORG SET RSA_PUBLIC_KEY='<public_key_contents>';
```

To get the public key contents without headers:
```bash
grep -v "BEGIN PUBLIC" rsa_key.pub | grep -v "END PUBLIC" | tr -d '\n'
```

### Step 3: Update .env File

```bash
# Remove or comment out password
# SNOWFLAKE_PASSWORD=your_password

# Add private key path
SNOWFLAKE_PRIVATE_KEY_PATH=/Users/Bob/snowflake_todo/rsa_key.p8

# Optional: If your private key is encrypted
# SNOWFLAKE_PRIVATE_KEY_PASSPHRASE=your_passphrase
```

### Step 4: Secure the Private Key

```bash
# Add to .gitignore (already configured)
echo "rsa_key.p8" >> .gitignore
echo "rsa_key.pub" >> .gitignore

# Set proper permissions
chmod 600 rsa_key.p8
```

---

## For Snowpark Container Services Deployment

When deployed in Snowpark Container Services, authentication is handled automatically via session tokens. Your Dockerfile should look like:

```dockerfile
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o server cmd/server/main.go

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/server .
COPY static ./static
COPY templates ./templates

# Snowpark will inject SNOWFLAKE_SESSION_TOKEN automatically
CMD ["./server"]
```

No credentials needed in the container! Snowflake provides:
- `SNOWFLAKE_SESSION_TOKEN` environment variable
- Automatic authentication within the Snowpark environment

---

## Current Authentication Issue

Your current error indicates the password is incorrect:
```
390100 (08004): Incorrect username or password was specified.
```

### To Fix Immediately

**Option 1: Fix Account Identifier**
Your account `ADVOCATE-MDP` likely needs the full identifier. Check your Snowflake URL:
- If URL is `https://xyz12345.us-east-1.aws.snowflakecomputing.com`
- Then account should be: `xyz12345.us-east-1.aws`

**Option 2: Switch to Key-Pair Auth** (Recommended)
Follow the steps above to set up key-pair authentication.

---

## Environment Variables Reference

```bash
# Required
SNOWFLAKE_ACCOUNT=your-account.region.cloud  # e.g., abc123.us-east-1.aws
SNOWFLAKE_USER=your.username@company.com
SNOWFLAKE_DATABASE=MDP_PHARMACY_WS_PROD
SNOWFLAKE_SCHEMA=OPIF
SNOWFLAKE_WAREHOUSE=MDP_PHARMACY_WH

# Authentication (choose ONE method)
# Method 1: Key-pair (recommended for local)
SNOWFLAKE_PRIVATE_KEY_PATH=/path/to/rsa_key.p8
# SNOWFLAKE_PRIVATE_KEY_PASSPHRASE=optional_if_encrypted

# Method 2: Password (fallback)
# SNOWFLAKE_PASSWORD=your_password

# Method 3: Session Token (automatic in Snowpark)
# SNOWFLAKE_SESSION_TOKEN=<injected_by_snowpark>

# Optional
PORT=8080
```

---

## Testing Your Connection

```bash
# Run the server
go run cmd/server/main.go

# Check the logs for:
# - "Using key-pair authentication" (good!)
# - "Successfully connected to Snowflake" (success!)
```

---

## Troubleshooting

### "failed to load private key"
- Check the file path is correct
- Verify file permissions: `chmod 600 rsa_key.p8`
- Ensure the key is in PEM format (PKCS#8 or PKCS#1)

### "390100: Incorrect username or password"
- Verify account identifier format
- Check username spelling
- If using password, verify it's correct
- If using key-pair, verify public key is added to user in Snowflake

### Connection timeout
- Check network connectivity
- Verify firewall rules allow outbound HTTPS (443)
- Try increasing timeout in `internal/database/snowflake.go:43`
