#!/usr/bin/env python3
"""Script para listar usuários de teste existentes"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlmodel import Session, select
from database.db import engine
from models.user import User

def list_users():
    """Lista todos os usuários no banco de dados"""
    with Session(engine) as session:
        statement = select(User)
        users = session.exec(statement).all()
        
        if not users:
            print("Nenhum usuário encontrado no banco de dados.")
            return
        
        print("=== USUÁRIOS DE TESTE DISPONÍVEIS ===\n")
        for user in users:
            print(f"👤 ID: {user.id}")
            print(f"🔑 Username: {user.username}")
            print(f"📧 Email: {user.email}")
            print(f"👨‍💼 Nome: {user.full_name}")
            print(f"🎭 Tipo: {user.user_type}")
            print(f"✅ Ativo: {user.active}")
            print(f"📅 Criado: {user.created_at}")
            print("-" * 40)

if __name__ == "__main__":
    list_users()
