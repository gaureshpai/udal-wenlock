# Pharmacy Medicine Availability Display

A web-based display system for showing medicine availability in a pharmacy. It fetches data from a public Google Sheet, translates medicine names to Kannada, and displays them on a continuously scrolling screen. A key feature is its offline capability, which ensures the display remains operational even without an active internet connection.

## Features

*   **Live Data Source**: Fetches the list of medicines and their availability directly from a designated public Google Sheet.
*   **Automatic Translation**: On-the-fly transliteration of medicine names into Kannada using an external API, with results cached locally to minimize redundant API calls.
*   **Robust Offline Capability**:
    *   Automatically caches all data (including translations) to a local `medicines.csv` file.
    *   If the Google Sheet is unreachable for any reason (e.g., internet outage), the server seamlessly falls back to serving the last known data from the local CSV file.
    *   This ensures the display remains functional and is always showing the most recently saved information.
*   **Dynamic Display**: A clean, full-screen, auto-scrolling interface designed for public information screens.
*   **Real-time Sync**: Periodically syncs with the Google Sheet (every 60 seconds) to keep the data fresh. It only writes to the local file if changes are detected.

## How It Works

The system is composed of a Node.js backend server and a simple HTML/CSS/JS frontend.

1.  **Server (`server.js`)**:
    *   Runs on port `3000`.
    *   On startup and every 60 seconds thereafter, it attempts to fetch the latest data from the Google Sheet.
    *   It compares the fetched data with its local cache (`medicines.csv`).
    *   If a medicine name has not been translated to Kannada before, it calls an external transliteration API.
    *   If any changes are detected (new medicines, different availability, new translations), it overwrites the `medicines.csv` file with the complete, updated dataset.
    *   If the fetch fails, it loads the data from `medicines.csv` into memory and serves that instead.
2.  **Frontend (`public/display.html`)**:
    *   A simple web page that makes an API call to the backend's `/medicines/available` endpoint.
    *   It receives a paginated list of available medicines and renders them in a table.
    *   The page automatically scrolls through all available pages of data, creating a continuous loop suitable for an unattended display.

## Setup and Configuration

1.  **Install Node.js**: If you don't have Node.js installed, download and install it from [nodejs.org](https://nodejs.org/).

2.  **Install Dependencies**: Navigate to the `prod/pharmacy` directory in your terminal and run:
    ```bash
    npm install
    ```

3.  **Configure Google Sheet**:
    *   Create a Google Sheet.
    *   Set the sharing permissions to **"Anyone with the link can view"**.
    *   The sheet should have a header row with at least two columns: one for the medicine name and one for its availability. The column names can be flexible (e.g., "Name", "Available", "Medicine Name").
    *   The availability column should use values like `TRUE`/`FALSE`, `yes`/`no`, or `1`/`0`.
    *   Open the `server.js` file and update the `SHEET_ID` constant with the ID of your Google Sheet (found in the sheet's URL).

4.  **Run the Server**: Open your terminal in the `prod/pharmacy` directory and run:
    ```bash
    npm start
    ```
    The server will start on `http://localhost:3000`.

## Accessing the Display

*   Once the server is running, open a web browser and navigate to `http://localhost:3000/display.html`.

## API Endpoints

*   `GET /medicines`: Returns the entire list of medicines (both available and unavailable) from the in-memory cache.
*   `GET /medicines/available`: Returns a paginated list of only the available medicines. This is the endpoint used by the display.
