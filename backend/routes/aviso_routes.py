from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from typing import List
from database.session import get_session
from models.aviso import Aviso
from datetime import datetime

router = APIRouter(prefix="/avisos", tags=["avisos"])

@router.post("/", response_model=Aviso)
def create_aviso(
    aviso_data: Aviso,
    session: Session = Depends(get_session)
):
    # Para MVP, author_id fixo
    aviso = Aviso(
        title=aviso_data.title,
        content=aviso_data.content,
        target_classroom=aviso_data.target_classroom,
        author_id=1
    )
    session.add(aviso)
    session.commit()
    session.refresh(aviso)
    return aviso

@router.get("/", response_model=List[Aviso])
def read_avisos(
    skip: int = 0,
    limit: int = 100,
    session: Session = Depends(get_session)
):
     statement = select(Aviso).offset(skip).limit(limit)
     avisos = session.exec(statement).all()
     return avisos

@router.get("/{aviso_id}", response_model=Aviso)
def read_aviso(
    aviso_id: int,
    session: Session = Depends(get_session)
):
    aviso = session.get(Aviso, aviso_id)
    if not aviso:
        raise HTTPException(status_code=404, detail="Aviso not found")
    return aviso

@router.put("/{aviso_id}", response_model=Aviso)
def update_aviso(
    aviso_id: int,
    aviso_data: Aviso,
    session: Session = Depends(get_session)
):
    aviso = session.get(Aviso, aviso_id)
    if not aviso:
        raise HTTPException(status_code=404, detail="Aviso not found")
    # Atualizar campos permitidos para MVP
    update_data = aviso_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        if key not in ["id", "author_id", "created_at"]:
            setattr(aviso, key, value)
    aviso.updated_at = datetime.now()
    session.add(aviso)
    session.commit()
    session.refresh(aviso)
    return aviso

@router.delete("/{aviso_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_aviso(
    aviso_id: int,
    session: Session = Depends(get_session)
):
    aviso = session.get(Aviso, aviso_id)
    if not aviso:
        raise HTTPException(status_code=404, detail="Aviso not found")
    session.delete(aviso)
    session.commit()
    return None