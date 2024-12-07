#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Install gnupg, curl, and essential tools
echo "Step 1: Installing gnupg, curl, and essential tools..."
sudo apt-get update
sudo apt-get install -y gnupg curl wget software-properties-common lsb-release

# Step 2: Install MongoDB
if command_exists mongod; then
    echo "MongoDB is already installed. Skipping installation."
else
    echo "Installing the latest MongoDB..."

    # Import the MongoDB public GPG key
    echo "Importing MongoDB public GPG key..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-org-7.0.gpg

    # Create a list file for MongoDB
    echo "Creating a list file for MongoDB..."
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-org-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

    # Reload local package database
    echo "Reloading local package database..."
    sudo apt-get update

    # Install MongoDB
    echo "Installing MongoDB packages..."
    sudo apt-get install -y mongodb-org

    # Start MongoDB service
    echo "Starting MongoDB service..."
    sudo systemctl start mongod

    # Enable MongoDB service on boot
    echo "Enabling MongoDB service on boot..."
    sudo systemctl enable mongod

    # Verify MongoDB installation
    if systemctl is-active --quiet mongod; then
        echo "MongoDB has been successfully installed and is running."
    else
        echo "MongoDB installation failed. Please check logs for details."
        exit 1
    fi
fi

# Step 3: Install Redis
if command_exists redis-server; then
    echo "Redis is already installed. Skipping installation."
else
    echo "Installing the latest Redis..."

    # Add Redis PPA for the latest version
    echo "Adding Redis PPA..."
    sudo add-apt-repository ppa:redislabs/redis -y

    # Reload local package database
    echo "Reloading local package database..."
    sudo apt-get update

    # Install Redis
    echo "Installing Redis..."
    sudo apt-get install -y redis

    # Start Redis service
    echo "Starting Redis service..."
    sudo systemctl start redis-server

    # Enable Redis service on boot
    echo "Enabling Redis service on boot..."
    sudo systemctl enable redis-server

    # Verify Redis installation
    if systemctl is-active --quiet redis-server; then
        echo "Redis has been successfully installed and is running."
    else
        echo "Redis installation failed. Please check logs for details."
        exit 1
    fi
fi

# Step 4: Install Go
if command_exists go; then
    echo "Go is already installed. Skipping installation."
else
    echo "Installing the latest Go..."

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

    # Apply changes to the current shell
    echo "Applying changes to the current shell..."
    source "$HOME/.profile"

    # Verify the Go installation
    echo "Verifying Go installation..."
    go version

    if [ $? -eq 0 ]; then
        echo "Go has been successfully installed."
    else
        echo "Go installation failed. Please check logs for details."
        exit 1
    fi

    # Cleanup Go tarball
    echo "Cleaning up Go tarball..."
    rm -f "$GO_TARBALL"
fi

# Post-installation: Display the status of MongoDB, Redis, and Go
echo ""
echo "Displaying the status of MongoDB, Redis, and Go..."

echo "MongoDB status:"
sudo systemctl status mongod --no-pager

echo ""
echo "Redis status:"
sudo systemctl status redis-server --no-pager

echo ""
echo "Go version:"
go version

echo ""
echo "MongoDB, Redis, and Go have been installed and configured successfully."
