#!/usr/bin/env python3
"""Script para criar avisos de teste no banco de dados"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlmodel import Session
from database.db import engine
from models.aviso import Aviso
from datetime import datetime

def create_test_avisos():
    """Cria avisos de teste no banco de dados"""
    with Session(engine) as session:
        # Criar avisos de teste
        avisos = [
            Aviso(
                title="Reunião de Pais",
                content="Reunião com os pais na sexta-feira às 18h para discutir o desenvolvimento das crianças.",
                author_id=1,
                target_classroom=None
            ),
            Aviso(
                title="Festa Junina",
                content="Tragam os alunos vestidos a caráter para a festa junina na próxima semana.",
                author_id=1,
                target_classroom=None
            ),
            Aviso(
                title="Alerta de Saúde",
                content="Caso de piolho identificado. Verifiquem as crianças em casa.",
                author_id=1,
                target_classroom=None
            ),
        ]
        
        for aviso in avisos:
            session.add(aviso)
        
        session.commit()
        
        print(f"Criados {len(avisos)} avisos de teste")

if __name__ == "__main__":
    create_test_avisos()
