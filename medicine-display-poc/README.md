# Medicine Display POC

This project is a proof-of-concept for a simple medicine availability display system for hospitals or pharmacies.

It consists of a Node.js backend with two main components:
1.  A web server (`server.js`) that serves the admin and display pages and provides a REST API to manage the medicine list.
2.  A discovery server (`server2.js`) that uses SSDP (UPnP) to broadcast the service on the network, allowing LG SmartSign TVs and other compatible devices to discover it automatically.

## Features

*   **Admin Interface:** A simple web page (`/admin.html`) to add, remove, and toggle the availability of medicines.
*   **Public Display:** A clean interface (`/display.html`) to show the list of available medicines, designed for public-facing screens.
*   **REST API:** A simple API to manage the medicine list.
*   **HTTPS Support:** The web server uses HTTPS.
*   **SSDP Discovery:** The server can be automatically discovered on the network.

## Project Structure

```
.
├── data/
│   └── medicines.json      # Stores the medicine list
├── public/
│   ├── admin.html          # Admin interface
│   ├── display.html        # Public display page
│   ├── dd.xml              # UPnP device description
│   └── wenlock_logo.png
├── ssl/
│   └── ...                 # SSL certificate files
├── .gitignore
├── package.json
├── server.js               # The main web server
└── server2.js              # The SSDP discovery server
```

## Setup and Running

1.  **Prerequisites:**
    *   Node.js and npm installed.
    *   An SSL certificate (for development, a self-signed certificate can be used and placed in the `ssl` folder).

2.  **Installation:**
    ```bash
    npm install
    ```

3.  **Configuration:**
    *   **IP Address:** Before starting, you need to configure the server's IP address in the `public/dd.xml` file. Find the line `<presentationURL>http://192.168.29.76:3000/display.html</presentationURL>` and replace `192.168.29.76` with the actual IP address of the server computer.
    *   **SSL:** Make sure your SSL certificate and key files are in the `ssl/` directory and are correctly referenced in `server.js`.

4.  **Running the Server:**
    ```bash
    npm start
    ```
    This will start both the web server and the discovery server. The web server will be available at `https://<your-server-ip>:3000`.

## How it Works

1.  When the server starts, `server2.js` begins broadcasting SSDP messages on the network.
2.  These messages contain a URL pointing to the `dd.xml` file.
3.  An LG SmartSign TV on the same network will receive these broadcasts and read the `dd.xml` file.
4.  The `dd.xml` file contains a `<presentationURL>` tag that tells the TV which URL to open. In this case, it's the `display.html` page.
5.  The TV then opens the `display.html` page, which fetches the medicine data from the server's REST API and displays it.
