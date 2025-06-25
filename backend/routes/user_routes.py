from fastapi import APIRouter
from models.user import User

router = APIRouter(prefix="/login", tags=["Login"])

@router.get("/")
def login_exemplo():
    return {"message": "Endpoint de login"}
