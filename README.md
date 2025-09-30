# Aurora Key API

This repository now includes a small FastAPI backend that can be used in a
school project to issue, verify, and revoke access keys for the in-game UI
contained in the Roblox scripts.  The service stores its data in
`data/keys.json`, which makes it easy to reset during testing or class
presentations.

## Getting started

1. Create a virtual environment and install dependencies:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```
2. Launch the development server:
   ```bash
   uvicorn app.main:app --reload
   ```
3. Open [http://localhost:8000/docs](http://localhost:8000/docs) to explore the
   automatically generated API documentation.

## Available endpoints

- `GET /health` – quick status check.
- `POST /keys` – issue a new key. Optionally include an owner name and key
  lifespan in hours (up to 30 days).
- `POST /keys/verify` – verify that a key exists and has not been revoked or
  expired.
- `POST /keys/revoke` – revoke an existing key.
- `GET /keys/{key}` – fetch the stored metadata for a key without validation.

All responses are JSON. Because the storage is a plain JSON file, you can
inspect or edit the data manually if you want to pre-seed test keys for a
presentation.
