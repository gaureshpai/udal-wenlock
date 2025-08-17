# User Guide: Medicine Display System

This guide explains how to set up and use the Medicine Display System on an LG SmartSign TV.

## Part 1: Setting up the Server

Before you can use the display, you need to start the server application on a computer.

1.  **Find the Computer's IP Address:**
    *   Open the Command Prompt on your Windows computer. You can find it by searching for "cmd" in the Start Menu.
    *   In the black window that appears, type `ipconfig` and press Enter.
    *   Look for the "IPv4 Address". It will look something like `192.168.1.10`. This is your server's IP address. Write it down.

2.  **Update the Configuration:**
    *   Open the file `public\dd.xml` in a text editor (like Notepad).
    *   Find the line that says `<presentationURL>http://192.168.29.76:3000/display.html</presentationURL>`.
    *   Replace `192.168.29.76` with the IP address you found in the previous step.
    *   Save and close the file.

3.  **Start the Server:**
    *   Open the Command Prompt (if you closed it).
    *   Navigate to the project directory by typing: `cd D:\webdev\udal-wenlock\medicine-display-poc` and press Enter.
    *   Type `npm install` and press Enter. This will download the necessary files for the server.
    *   Type `npm start` and press Enter. You should see messages that the servers are running. **Keep this window open.** The server is now running.

## Part 2: Connecting the LG TV

Now that the server is running, you can connect the LG TV to it.

1.  **Connect to the Network:** Make sure the TV is connected to the same hospital network as your server computer (either by Wi-Fi or a network cable).

2.  **Select the Input Source:**
    *   Press the "Input" or "Source" button on the TV remote.
    *   In the list of inputs, look for an option like "Network", "DLNA", "UPnP", or the name of your server "Medicine Display POC". The exact name can vary depending on the TV model.
    *   Select this source.

3.  **View the Display:**
    *   The TV should now automatically find the server and load the medicine display page.

**Troubleshooting:**

*   **Server not found:** If the TV cannot find the server automatically, you can try to open the TV's web browser and manually type in the address: `http://<YOUR_IP_ADDRESS>:3000/display.html` (replace `<YOUR_IP_ADDRESS>` with the IP you wrote down). Note that you might get a certificate warning.
*   **Check the IP:** Double-check that the IP address in the `dd.xml` file is correct.
*   **Firewall:** Make sure the firewall on the server computer is not blocking the connection.

## Part 3: Managing the Medicine List

To add or remove medicines from the display, you need to use the admin page.

1.  On a computer or tablet connected to the same network, open a web browser (like Chrome, Firefox, or Edge).
2.  Go to the following address: `https://<YOUR_IP_ADDRESS>:3000/admin.html` (replace `<YOUR_IP_ADDRESS>` with the server's IP address).
3.  You might see a security warning because the site is using a self-signed certificate. You can safely proceed.
4.  On the admin page, you can add new medicines, mark them as available or unavailable, or delete them. The changes will appear on the TV display automatically.
