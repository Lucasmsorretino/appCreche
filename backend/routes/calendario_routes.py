from fastapi import APIRouter
from auth import decode_access_token
from fastapi import Depends
from models.calendario import CalendarioEvento

router = APIRouter(prefix="/calendario", tags=["Calendário"])

@router.get("/")
def listar_eventos(user_data=Depends(decode_access_token)):
    return [{"tipo": "feriado", "data": "2025-04-21", "descricao": "Tiradentes"}]