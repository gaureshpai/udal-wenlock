# Medicine Display POC

This project is a Proof-of-Concept (POC) for a simple medicine display system. It features a Node.js Express backend, a public display interface, and an administration interface for managing medicine data.

## Project Structure

*   `server.js`: The backend server application.
*   `public/`: Contains static frontend files.
    *   `display.html`: The main public display page for medicines.
    *   `admin.html`: The administration page for managing medicine data.
*   `data/medicines.json`: Stores the medicine data in JSON format.
*   `start_server.vbs`: A VBScript to easily start the Node.js server.

## Features

*   **Display Medicines**: Shows a list of medicines on a public-facing display.
*   **Add/Delete Medicines**: Allows administrators to add new medicines or remove existing ones.
*   **RESTful API**: Provides API endpoints for managing medicine data.

## Setup and Running

To set up and run this project, follow these steps:

1.  **Install Node.js**: If you don't have Node.js installed, download and install it from [nodejs.org](https://nodejs.org/).
2.  **Install Dependencies**: Navigate to the project root directory in your terminal and run:
    ```bash
    npm install
    ```
3.  **Start the Server**:
    *   **Using VBScript (Windows)**: Double-click `start_server.vbs`. This will start the server in the background.
    *   **Using Command Line**: Open your terminal in the project root and run:
        ```bash
        node server.js
        ```
    The server will run on `http://localhost:3000`.

## Usage

*   **Medicine Display**: Open `http://localhost:3000/display.html` in your web browser to see the medicine display.
*   **Admin Panel**: Open `http://localhost:3000/admin.html` in your web browser to access the administration panel. From here, you can add or delete medicines.

## API Endpoints

The server exposes the following API endpoints:

*   **GET `/api/medicines`**:
    *   **Description**: Retrieves all medicine data.
    *   **Response**: A JSON array of medicine objects.
*   **POST `/api/medicines`**:
    *   **Description**: Adds a new medicine or updates existing medicine data.
    *   **Request Body**: A JSON object representing the medicine to add/update.
    *   **Response**: The updated list of medicines.