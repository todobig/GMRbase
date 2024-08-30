#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Install gnupg and curl if not already installed
echo "Step 1: Installing gnupg and curl..."
sudo apt-get update
sudo apt-get install -y gnupg curl

# Step 2: Check if MongoDB is already installed
if command_exists mongod; then
    echo "MongoDB is already installed. Skipping installation."
else
    echo "Installing MongoDB..."

    # Import the MongoDB public GPG key
    echo "Importing MongoDB public GPG key..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg

    # Create a list file for MongoDB
    echo "Creating a list file for MongoDB..."
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

    # Reload local package database
    echo "Reloading local package database..."
    sudo apt-get update

    # Install MongoDB packages
    echo "Installing MongoDB packages..."
    sudo apt-get install -y mongodb-org

    # Check if MongoDB was installed successfully
    mongo_installed=$(dpkg-query -W -f='${Status}' mongodb-org 2>/dev/null | grep -c "ok installed")
    if [ $mongo_installed -eq 1 ]; then
        echo "MongoDB Community Edition has been successfully installed."

        # Start MongoDB service
        echo "Starting MongoDB service..."
        sudo systemctl start mongod

        # Handle errors related to mongod service not found
        if ! systemctl status mongod &> /dev/null; then
            echo "Failed to start mongod.service. Running 'sudo systemctl daemon-reload'..."
            sudo systemctl daemon-reload
            echo "Retrying to start mongod.service..."
            sudo systemctl start mongod
        fi

        # Enable MongoDB to start on system boot
        echo "Enabling MongoDB to start on system boot..."
        sudo systemctl enable mongod
    else
        echo "MongoDB Community Edition installation failed. Please check logs for errors."
        exit 1
    fi
fi

# Step 3: Check if Go is already installed
if command_exists go; then
    echo "Go is already installed. Skipping installation."
else
    echo "Installing Go..."

    # Fetch the latest version of Go
    LATEST_GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | grep -o 'go[0-9]\+\.[0-9]\+\.[0-9]\+')
    GO_TARBALL="${LATEST_GO_VERSION}.linux-amd64.tar.gz"
    GO_DOWNLOAD_URL="https://go.dev/dl/${GO_TARBALL}"

    echo "Latest Go version: $LATEST_GO_VERSION"
    echo "Downloading Go from $GO_DOWNLOAD_URL..."

    # Download the latest version of Go
    wget "$GO_DOWNLOAD_URL"

    # Remove any previous Go installation
    echo "Removing any previous Go installation..."
    sudo rm -rf /usr/local/go

    # Extract the downloaded Go tarball into /usr/local
    echo "Extracting Go into /usr/local..."
    sudo tar -C /usr/local -xzf "$GO_TARBALL"

    # Add /usr/local/go/bin to the PATH environment variable
    echo "Adding Go to the PATH..."
    if ! grep -qF "/usr/local/go/bin" "$HOME/.profile"; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.profile"
    fi

    # Apply changes to the current shell and reload
    echo "Applying changes to the current shell..."
    source "$HOME/.profile"

    # Verify the Go installation
    echo "Verifying Go installation..."
    go version

    if [ $? -eq 0 ]; then
        echo "Go has been successfully installed."
    else
        echo "Go installation failed. Please check logs for errors."
        exit 1
    fi
fi

# Step 4: Check if Redis is already installed
if command_exists redis-server; then
    echo "Redis is already installed. Skipping installation."
else
    echo "Installing Redis..."

    # Install Redis
    sudo apt-get install -y redis-server

    # Start and enable Redis service
    echo "Starting and enabling Redis service..."
    sudo systemctl start redis-server
    sudo systemctl enable redis-server

    # Verify Redis installation
    echo "Verifying Redis installation..."
    if systemctl is-active --quiet redis-server; then
        echo "Redis has been successfully installed and is running."
    else
        echo "Redis installation failed. Please check logs for errors."
        exit 1
    fi
fi

# Post-installation: Display the status of MongoDB, Go, and Redis

echo ""
echo "Displaying the status of MongoDB, Go, and Redis..."

echo "MongoDB status:"
sudo systemctl status mongod --no-pager

echo ""
echo "Go version:"
go version

echo ""
echo "Redis status:"
sudo systemctl status redis-server --no-pager

echo ""
echo "MongoDB, Go, and Redis have been installed and configured successfully."
