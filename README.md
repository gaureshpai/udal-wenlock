# UDAL Wenlock Hospital Display System

This project is a collection of services designed to provide real-time, public-facing information displays for various departments at Wenlock Hospital. The system is built as a set of independent micro-services, each handling a specific display need, such as medicine availability or blood bank status.

The primary goal is to create a low-cost, low-maintenance system that can run on simple hardware (like a Raspberry Pi or any old computer with a web browser) and be managed through a familiar interface (Google Sheets).

## Services

This repository contains the following services, located in the `prod/` directory:

### 1. Pharmacy Medicine Availability (`prod/pharmacy`)

A display system for showing which medicines are currently available at the pharmacy.

*   **Data Source**: A public Google Sheet.
*   **Features**:
    *   Live updates from the Google Sheet.
    *   On-the-fly translation of medicine names to Kannada.
    *   Offline capability: Caches data to a local CSV file and serves it if the internet connection is lost.
    *   A vertically scrolling display suitable for public screens.
*   **Tech**: Node.js, Express, PapaParse for CSV handling.
*   **Port**: `3000`

### 2. Blood Bank Display (`prod/blood-bank`)

A dual-screen system for the hospital's blood bank.

*   **Data Source**: Google Apps Script endpoints (which read from a Google Sheet).
*   **Features**:
    *   **Blood Requests Screen**: A live, scrolling list of urgent blood needs.
    *   **Inventory Screen**: A rotating dashboard showing the current stock of various blood components (e.g., FFP, Platelets) for each blood group.
    *   Automatic Kannada transliteration for patient and component names.
    *   Emergency requests are prioritized at the top of the list.
*   **Tech**: Node.js, Express.
*   **Port**: `3001`

## Architecture Overview

The system is designed with simplicity and resilience in mind.

*   **Decoupled Services**: Each service (Pharmacy, Blood Bank) is independent. They run on different ports and do not communicate with each other. This means a failure in one service will not affect the others.
*   **Google Sheets as a "Database"**: Non-technical staff can easily update the information by editing a Google Sheet, which requires no special training.
*   **Web-Based Displays**: The frontends are simple HTML, CSS, and JavaScript pages, making them compatible with any modern web browser. This avoids the need for native applications and complex deployments.
*   **Resilience**: The pharmacy service includes an offline mode, demonstrating a pattern that can be applied to other services to ensure the displays remain functional even during network outages.
*   **Automation**: The displays are designed for unattended operation, automatically fetching data and updating themselves without manual intervention.

## Getting Started

To run any of the services:

1.  **Prerequisites**: Make sure you have [Node.js](https://nodejs.org/) installed.
2.  **Navigate to the service directory**:
    ```bash
    cd prod/pharmacy
    # or
    cd prod/blood-bank
    ```
3.  **Install dependencies**:
    ```bash
    npm install
    ```
4.  **Run the server**:
    ```bash
    npm start
    ```
5.  Refer to the individual `README.md` file within each service's directory for more detailed setup and configuration instructions.

## Deployment

Each service is a self-contained Node.js application. For a production environment, it is recommended to run them using a process manager like `pm2` to ensure they restart automatically if they crash.

The `service.vbs` files included in each service directory are scripts used to run the Node.js servers as background processes on Windows, which is how the system is currently deployed at Wenlock Hospital.
