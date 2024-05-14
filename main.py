from fastapi import FastAPI
import random
from fastapi.middleware.cors import CORSMiddleware
import requests
app = FastAPI()

# Allow CORS for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/data")
def get_data():
    # Example of generating random data
    data = [
        {"ID": i, "SID": random.randint(1, 10), "Value": random.uniform(20.0, 30.0), "Time": "2024-05-12T21:21:18.000Z"}
        for i in range(10)
    ]
    return data
@app.get("/api/get_sensor_data")
def get_sensor_data():
    # URL của Node-RED endpoint
    node_red_url = "http://localhost:1880/select"

    try:
        # Lấy dữ liệu từ Node-RED
        response = requests.get(node_red_url)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        raise HTTPException(status_code=500, detail=str(e))
    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
