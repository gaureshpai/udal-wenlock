# Generating SSL Certificates for Development

This document explains how to generate the self-signed SSL certificates required to run this project's server over HTTPS in a development environment.

These files are sensitive and are ignored by Git (`.gitignore`). Each developer must generate their own local set of certificates.

## Step 1: Install OpenSSL

OpenSSL is a standard tool for creating and managing SSL/TLS certificates. It is often pre-installed on Linux and macOS. On Windows, it is included with Git Bash.

To check if you have it, open a terminal or command prompt and run:

```bash
openssl version
```

If you do not have it installed, you can get it from:
*   **Windows:** Install [Git for Windows](https://git-scm.com/download/win) or use a package manager like [Chocolatey](https://chocolatey.org/) (`choco install openssl`).
*   **macOS (Homebrew):** `brew install openssl`
*   **Linux (Debian/Ubuntu):** `sudo apt-get install openssl`

## Step 2: Generate the Certificate and Key

1.  Navigate to the root of the project directory in your terminal.

2.  If the `ssl` directory does not exist, create it:
    ```bash
    mkdir ssl
    ```

3.  Run the following command to generate a new private key (`server.key`) and a self-signed certificate (`server.pem`):

    ```bash
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ssl/server.key -out ssl/server.pem
    ```

## Step 3: Answer the Certificate Prompts

The command will ask you for information to embed in the certificate. For local development, most fields can be left blank.

The most important field is **Common Name (CN)**, which must match the address you use to access the server.

*   **Common Name (e.g. server FQDN or YOUR name) []:**
    *   Enter `localhost` if you are accessing the server from the same machine.
    *   Enter the server's local network IP address (e.g., `192.168.1.100`) if you need to access it from other devices, like the LG SmartSign TV.

All other fields (Country, State, etc.) can be left at their default values by pressing Enter.

## Step 4: Update the Server Configuration

Finally, ensure that `server.js` is configured to use these newly generated files.

The `options` object in `server.js` should look like this:

```javascript
const options = {
  key: fs.readFileSync('./ssl/server.key'),
  cert: fs.readFileSync('./ssl/server.pem')
};
```

Your server is now ready to run over HTTPS using your local, self-signed SSL certificate.