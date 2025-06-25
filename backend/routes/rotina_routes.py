from fastapi import APIRouter
from auth import decode_access_token
from fastapi import Depends
from models.rotina import Rotina

router = APIRouter(prefix="/rotina", tags=["Rotina"])


@router.get("/")
def listar_rotina(user_data=Depends(decode_access_token)):
    return [{"data": "2025-04-06", "descricao": "Almoçou e dormiu após o almoço."}]

