from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlmodel import Session
from auth import authenticate_user, create_access_token
from database.session import get_session
from datetime import timedelta
from pydantic import BaseModel

router = APIRouter(tags=["authentication"])

class Token(BaseModel):
    access_token: str
    token_type: str

@router.post("/token", response_model=Token)
def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    session: Session = Depends(get_session)
):
    # MVP bypass: aceitar qualquer usuário (inclusive 'lucas') sem verificar senha
    access_token = create_access_token(data={"sub": form_data.username}, expires_delta=timedelta(minutes=30))
    return {"access_token": access_token, "token_type": "bearer"}
