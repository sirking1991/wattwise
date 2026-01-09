#!/bin/bash
set -e

KEYSTORE_DIR="android/app"
KEYSTORE_FILE="$KEYSTORE_DIR/upload-keystore.jks"
PROPERTIES_FILE="android/key.properties"

# Ensure directory exists
mkdir -p "$KEYSTORE_DIR"

if [ -f "$KEYSTORE_FILE" ]; then
    echo "Warning: Keystore $KEYSTORE_FILE already exists."
    echo "Skipping generation to avoid overwriting existing keys."
    echo "If you want to regenerate, please delete the file and run this script again."
else
    echo "Generating secure password..."
    # Generate a random password
    PASSWORD=$(openssl rand -base64 24)

    echo "Generating keystore at $KEYSTORE_FILE..."
    # Non-interactive keytool generation
    keytool -genkey -v -keystore "$KEYSTORE_FILE" \
        -storepass "$PASSWORD" \
        -keypass "$PASSWORD" \
        -alias upload \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -dname "CN=WattWise Admin, OU=Engineering, O=BizWerks Solutions, L=Metropolis, ST=State, C=US"
    
    echo "Keystore generated successfully."

    echo "Creating $PROPERTIES_FILE..."
    cat > "$PROPERTIES_FILE" <<EOF
storePassword=$PASSWORD
keyPassword=$PASSWORD
keyAlias=upload
storeFile=app/upload-keystore.jks
EOF
    echo "$PROPERTIES_FILE created."
fi
