import os

from fastapi import FastAPI
from fastapi.responses import JSONResponse

if os.environ.get("ENV") == "PROD":
    app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)
else:
    app = FastAPI()


@app.get("/")
def read_root():
    return JSONResponse(content={"message": "Hello, World!"})
