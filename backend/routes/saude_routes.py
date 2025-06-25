from fastapi import APIRouter
from auth import decode_access_token
from fastapi import Depends
from models.saude import SaudeRecord

router = APIRouter(prefix="/saude", tags=["Saúde"])

@router.get("/")
def listar_saude(user_data=Depends(decode_access_token)):
    return [{"tipo": "medicamento", "descricao": "Paracetamol 10ml às 14h"}]