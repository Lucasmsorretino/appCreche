#!/usr/bin/env python3
"""Script para criar usuário de teste no banco de dados"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlmodel import Session
from database.db import engine
from models.user import User, UserType
from auth import get_password_hash

def create_test_user():
    """Cria usuário de teste no banco de dados"""
    with Session(engine) as session:
        # Verificar se usuário já existe
        existing_user = session.get(User, 1)
        if existing_user:
            print("Usuário de teste já existe!")
            return
        
        # Criar usuário de teste
        test_user = User(
            username="lucas",
            email="lucas@test.com",
            hashed_password=get_password_hash("senha123"),
            full_name="Lucas Test User",
            user_type=UserType.TEACHER,
            active=True
        )
        
        session.add(test_user)
        session.commit()
        session.refresh(test_user)
        
        print(f"Usuário de teste criado com ID: {test_user.id}")
        print(f"Username: {test_user.username}")
        print(f"Password: senha123")

if __name__ == "__main__":
    create_test_user()
