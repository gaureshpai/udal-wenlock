# Blood Bank Display System

This service provides a real-time display system for a hospital's blood bank, showing both urgent blood requests and the current inventory of blood components. It is composed of two separate displays:

1.  **Blood Requests Display**: Shows a live, scrolling list of patients who require blood, including their name, age, required blood component, and the urgency of the request.
2.  **Blood Tally Display**: Shows a rotating dashboard of the current stock levels for various blood components (e.g., Packed Red Blood Cells, Platelets), broken down by blood group.

## Features

*   **Live Data**: Fetches data from a Google Apps Script endpoint, which in turn reads from a Google Sheet, ensuring the displayed information is always up-to-date.
*   **Dual Displays**: Manages two distinct screens for different but related information (requests vs. inventory).
*   **Automatic Translation**: Translates patient names and blood component names into Kannada for better local accessibility.
*   **Dynamic & Unattended**: The displays are designed to run continuously on public screens without any user interaction. The blood requests scroll automatically, and the tally display cycles through different blood components.
*   **Prioritized Display**: Emergency requests are automatically sorted and displayed at the top of the list.

## How It Works

### Blood Requests (`display.html`)

1.  A Node.js/Express server runs on port `3001`.
2.  The server polls a Google Apps Script URL every second for new or updated blood requests. To save bandwidth, it only fetches changes since the last successful poll.
3.  For each request, the patient's name and the required blood component are transliterated into Kannada using an external API.
4.  The processed data is kept in an in-memory cache.
5.  The frontend page (`public/display.html`) fetches this data from the server's `/data` endpoint and displays it in a vertically scrolling list.

### Blood Inventory Tally (`tally.html`)

1.  The frontend page (`public/tally.html`) directly fetches inventory data from a separate Google Apps Script endpoint.
2.  This page is self-contained; it does not rely on the Node.js server for data.
3.  It visualizes the stock data in tables, automatically rotating through different blood components (like FFP, Platelets, etc.) every few seconds.

## Setup and Configuration

1.  **Install Node.js**: If not already installed, download and install it from [nodejs.org](https://nodejs.org/).

2.  **Install Dependencies**: In the `prod/blood-bank` directory, run:
    ```bash
    npm install
    ```

3.  **Configure Google Apps Script**:
    *   The `server.js` file is configured to fetch data from a specific Google Apps Script URL. The `SECRET_KEY` is used for authenticating with this script.
    *   The `tally.html` file also contains a hardcoded URL and key for its data source.
    *   To use your own data source, you would need to deploy your own Google Apps Script and update the URLs and keys in `server.js` and `public/tally.html`.

4.  **Run the Server**:
    ```bash
    npm start
    ```
    The server will start on `http://localhost:3001`.

## Accessing the Displays

*   **Blood Requests**: Open a browser and navigate to `http://localhost:3001/display.html`.
*   **Blood Inventory**: Open a browser and navigate to `http://localhost:3001/tally.html`.
