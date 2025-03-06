from fastapi import FastAPI
import uvicorn
from app.routes import devices, users, remote, websocket

app = FastAPI()

app.include_router(users.router, prefix="/api")
app.include_router(devices.router, prefix="/api")
app.include_router(remote.router, prefix="/api")
app.include_router(websocket.router, prefix="/api")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)