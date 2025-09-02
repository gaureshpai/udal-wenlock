# Medicine Availability Display

A simple, web-based display system for showing medicine availability. It fetches data from a public Google Sheet, translates medicine names to Kannada, and displays them on a continuously scrolling screen. It also features an offline mode, serving data from a local cache if the internet is unavailable.

## Features

*   **Live Data Source**: Fetches data directly from a public Google Sheet.
*   **Automatic Translation**: On-the-fly translation of medicine names to Kannada using an external API.
*   **Offline Capability**: Automatically caches data in a local CSV file. If the Google Sheet is unreachable, the display will serve the last known data from this file.
*   **Dynamic Display**: Full-screen, auto-scrolling display suitable for public information screens.
*   **Real-time Sync**: Periodically syncs with the Google Sheet to keep the data fresh.

## How It Works

1.  A Node.js/Express server periodically fetches data from a designated public Google Sheet.
2.  For any medicine name that hasn't been translated, the server calls an external API (`transliteration.devnagri.com`) to generate the Kannada name.
3.  The complete, up-to-date data (including translations) is saved to a local `data/medicines.csv` file. This file acts as both a cache and an offline backup.
4.  A frontend page (`public/display.html`) fetches the latest data from the server and presents it in a paginated, auto-scrolling list.
5.  If the server fails to connect to the Google Sheet, it automatically falls back to serving the data from the local `medicines.csv` file, ensuring the display keeps running.

## Setup and Configuration

1.  **Install Node.js**: If you don't have Node.js installed, download and install it from [nodejs.org](https://nodejs.org/).

2.  **Install Dependencies**: Navigate to the project root directory in your terminal and run:
    ```bash
    npm install
    ```

3.  **Configure Google Sheet**:
    *   Create a Google Sheet.
    *   Set the sharing permissions to **"Anyone with the link can view"**.
    *   The sheet should **not** have a header row.
    *   The data should be structured in the first two columns:
        *   **Column A**: The medicine name in English.
        *   **Column B**: The availability status (e.g., `TRUE`, `FALSE`, `yes`, `no`, `1`, `0`).
    *   Open the `server.js` file and update the `SHEET_ID` constant with the ID of your Google Sheet (found in the sheet's URL).

4.  **Run the Server**: Open your terminal in the project root and run:
    ```bash
    npm start
    ```
    The server will run on `http://localhost:3000`.

## Accessing the Display

*   Once the server is running, open a web browser and navigate to `http://localhost:3000/display.html`.
